require "../../../src/term2"
require "log"
require "socket"
require "set"
require "openssl"

include Term2::Prelude

Log.setup_from_env

module ZuseApp
  alias ServerId = Int32
  alias DispatchProc = Proc(Term2::Message, Nil)

  PINK            = Term2::Color.from_hex("#DB2777")
  DARK_PINK       = Term2::Color.from_hex("#ac215f")
  STYLE_PINK      = Term2::Style.new.foreground(PINK)
  STYLE_PINK_B    = STYLE_PINK.copy.bold(true)
  STYLE_DIM       = Term2::Style.new.foreground(Term2::Color.from_hex("#6B7280"))
  STYLE_SEL       = Term2::Style.new.foreground(Term2::Color.from_hex("#000000")).background(PINK)
  STYLE_DARK_SEL  = Term2::Style.new.foreground(Term2::Color.from_hex("#000000")).background(DARK_PINK)
  STYLE_DARK_PINK = Term2::Style.new.foreground(DARK_PINK)

  TITLE_STYLE = Term2::Style.new
    .background(DARK_PINK)
    .foreground(Term2::Color.from_hex("#000000"))
    .bold(true)
    .padding(0, 1)

  BOX_STYLE = Term2::Style.new
    .border(Term2::Border.rounded)
    .border_foreground(PINK)

  enum Pane
    Servers
    Right
  end

  enum RightMode
    Form
    Chat
  end

  enum FormField
    Name
    Address
    Tls
    Nick
    Channels
    Submit
  end

  class IrcLineMsg < Term2::Message
    getter server_id : ServerId
    getter channel : String
    getter line : String

    def initialize(@server_id : ServerId, @channel : String, @line : String)
    end
  end

  class ConnectedMsg < Term2::Message
    getter server_id : ServerId

    def initialize(@server_id : ServerId)
    end
  end

  class DisconnectedMsg < Term2::Message
    getter server_id : ServerId
    getter error : Exception?

    def initialize(@server_id : ServerId, @error : Exception?)
    end
  end

  class ErrMsg < Term2::Message
    getter error : Exception

    def initialize(@error : Exception)
    end
  end

  struct ServerListItem
    include TC::List::Item

    getter id : ServerId
    getter channel : String
    getter title : String
    getter description : String

    def initialize(@id : ServerId, @title : String, @description : String, @channel : String = "")
    end

    def filter_value : String
      "#{@title} #{@description}".strip
    end
  end

  struct AddServerItem
    include TC::List::Item

    def filter_value : String
      ""
    end
  end

  struct ServerListStyles
    property normal_title : Term2::Style
    property normal_desc : Term2::Style
    property selected_title : Term2::Style
    property selected_desc : Term2::Style

    def initialize
      @normal_title = STYLE_PINK
      @normal_desc = STYLE_DIM
      @selected_title = STYLE_DARK_SEL
      @selected_desc = STYLE_DARK_SEL
    end
  end

  class ServerListDelegate
    include TC::List::ItemDelegate

    getter styles : ServerListStyles

    def initialize(@styles : ServerListStyles)
    end

    def height : Int32
      2
    end

    def spacing : Int32
      0
    end

    def update(msg : Term2::Msg, model : TC::List) : Term2::Cmd
      Term2::Cmds.none
    end

    def render(io : IO, model : TC::List, index : Int32, item : TC::List::Item) : Nil
      selected = index == model.index
      case item
      when AddServerItem
        style = selected ? styles.selected_title : styles.normal_title
        io << style.render("+ Add New Server") << "\n"
        io << styles.normal_desc.render("")
      when ServerListItem
        title = item.title
        desc = item.description
        if selected
          io << styles.selected_title.render(title) << "\n"
          io << styles.selected_desc.render(desc)
        else
          io << styles.normal_title.render(title) << "\n"
          io << styles.normal_desc.render(desc)
        end
      else
        style = selected ? styles.selected_title : styles.normal_title
        io << style.render(item.filter_value) << "\n"
        io << styles.normal_desc.render("")
      end
    end
  end

  class Server
    property id : ServerId
    property name : String
    property address : String
    property tls : Bool
    property nick : String
    property channels : Array(String)
    property channel_logs : Hash(String, Array(String))
    property joined : Set(String)
    property client : IrcClient?
    property connected : Bool
    property queued : Array(IrcLineMsg)

    def initialize(
      @id : ServerId,
      @name : String,
      @address : String,
      @tls : Bool,
      @nick : String,
      @channels : Array(String),
    )
      @channel_logs = Hash(String, Array(String)).new
      @joined = Set(String).new
      @client = nil
      @connected = false
      @queued = [] of IrcLineMsg
    end
  end

  struct IrcMessage
    getter prefix : String?
    getter command : String
    getter params : Array(String)

    def initialize(@prefix : String?, @command : String, @params : Array(String))
    end
  end

  class IrcClient
    @socket : IO?
    @write_lock : Mutex
    @connected : Bool
    @sent_connected_msg : Bool
    @dispatched_disconnect : Bool

    def initialize(@server : Server, @dispatch : DispatchProc)
      @socket = nil
      @write_lock = Mutex.new
      @connected = false
      @sent_connected_msg = false
      @dispatched_disconnect = false
    end

    def connect : Nil
      host, port = parse_host_port(@server.address)
      tcp = TCPSocket.new(host, port)
      @socket =
        if @server.tls
          context = OpenSSL::SSL::Context::Client.new
          OpenSSL::SSL::Socket::Client.new(tcp, context, sync_close: true)
        else
          tcp
        end

      @connected = true
      send_line("NICK #{@server.nick}")
      send_line("USER #{@server.nick} 0 * :#{@server.nick}")
      spawn { read_loop }
    rescue ex
      @connected = false
      dispatch_disconnect(ex)
    end

    def connected? : Bool
      @connected
    end

    def join(channel : String) : Nil
      @server.joined.add(channel)
      send_line("JOIN #{channel}")
    end

    def message(target : String, text : String) : Nil
      send_line("PRIVMSG #{target} :#{text}")
    end

    def nick(name : String) : Nil
      send_line("NICK #{name}")
    end

    def quit(message : String = "bye") : Nil
      send_line("QUIT :#{message}")
    end

    def close : Nil
      @connected = false
      @socket.try(&.close)
    end

    private def read_loop : Nil
      io = @socket
      return unless io

      loop do
        line = io.gets
        break if line.nil?
        text = line.rstrip("\r\n")
        handle_line(text)
      end
    rescue ex
      dispatch_disconnect(ex)
    ensure
      @connected = false
      dispatch_disconnect(nil)
    end

    private def handle_line(line : String) : Nil
      msg = parse_irc_message(line)
      case msg.command
      when "PING"
        payload = msg.params.last? || ""
        send_line("PONG :#{payload}")
      when "001"
        mark_connected
      when "PRIVMSG"
        handle_privmsg(msg)
      when "NOTICE"
        handle_notice(msg)
      when "JOIN"
        handle_join(msg)
      when "PART"
        handle_part(msg)
      when "QUIT"
        handle_quit(msg)
      when "332" # RPL_TOPIC
        handle_topic(msg)
      when "333" # RPL_TOPICWHOTIME
        handle_topic_who_time(msg)
      when "366" # RPL_ENDOFNAMES
        handle_end_of_names(msg)
      else
        handle_numeric_or_misc(msg)
      end
    end

    private def handle_privmsg(msg : IrcMessage) : Nil
      return if msg.params.size < 2
      target = msg.params[0]
      text = msg.params[1]
      nick = nick_from_prefix(msg.prefix)
      channel = dispatch_target(target)

      if action_message?(text)
        action_text = strip_action(text)
        line = "[#{timestamp}] * #{nick} #{action_text}"
        send_line_msg(channel, STYLE_DIM.render(line))
        send_line_msg("_sys", STYLE_DIM.render(line)) unless channel == "_sys"
        return
      end

      line = STYLE_PINK.render("[#{timestamp}] <#{nick}> #{text}")
      send_line_msg(channel, line)
      send_line_msg("_sys", line) unless channel == "_sys"
    end

    private def handle_notice(msg : IrcMessage) : Nil
      return if msg.params.size < 2
      target = msg.params[0]
      text = msg.params[1]
      channel = dispatch_target(target)
      line = STYLE_DIM.render("[#{timestamp}] -NOTICE- #{text}")
      send_line_msg(channel, line)
      send_line_msg("_sys", line) unless channel == "_sys"
    end

    private def handle_join(msg : IrcMessage) : Nil
      channel = msg.params.first? || ""
      nick = nick_from_prefix(msg.prefix)
      line = STYLE_DIM.render("[#{timestamp}] * #{nick} joined #{channel}")
      send_line_msg(channel, line) unless channel.empty?
      send_line_msg("_sys", line)
    end

    private def handle_part(msg : IrcMessage) : Nil
      channel = msg.params.first? || ""
      nick = nick_from_prefix(msg.prefix)
      line = STYLE_DIM.render("[#{timestamp}] * #{nick} left #{channel}")
      send_line_msg(channel, line) unless channel.empty?
      send_line_msg("_sys", line)
    end

    private def handle_quit(msg : IrcMessage) : Nil
      nick = nick_from_prefix(msg.prefix)
      line = STYLE_DIM.render("[#{timestamp}] * #{nick} quit")
      send_line_msg("_sys", line)
    end

    private def handle_topic(msg : IrcMessage) : Nil
      return if msg.params.size < 3
      channel = msg.params[1]
      topic = msg.params[2]
      line = STYLE_DIM.render("-- topic: #{topic}")
      send_line_msg(channel, line)
      send_line_msg("_sys", line)
    end

    private def handle_topic_who_time(msg : IrcMessage) : Nil
      return if msg.params.size < 4
      channel = msg.params[1]
      who = msg.params[2]
      ts = msg.params[3]
      line = STYLE_DIM.render("-- set by #{who} @ #{ts}")
      send_line_msg(channel, line)
      send_line_msg("_sys", line)
    end

    private def handle_end_of_names(msg : IrcMessage) : Nil
      return if msg.params.size < 2
      channel = msg.params[1]
      line = STYLE_DIM.render("-- end of names")
      send_line_msg(channel, line)
      send_line_msg("_sys", line)
    end

    private def handle_numeric_or_misc(msg : IrcMessage) : Nil
      ignore = ["315", "352", "354", "b09"]
      return if ignore.includes?(msg.command)

      if msg.command == "ERROR"
        text = msg.params.join(" ")
        send_line_msg("_sys", STYLE_DIM.render("[#{timestamp}] #{text}"))
        return
      end

      if numeric?(msg.command)
        dest = "_sys"
        msg.params.each do |param|
          if param.starts_with?("#")
            dest = param
            break
          end
        end
        text = msg.params.join(" ")
        line = STYLE_DIM.render("[#{timestamp}] #{text}")
        send_line_msg(dest, line)
        send_line_msg("_sys", line) unless dest == "_sys"
        return
      end

      if ["CAP", "AUTHENTICATE", "903", "904"].includes?(msg.command)
        text = msg.params.join(" ")
        line = STYLE_DIM.render("[#{timestamp}] #{msg.command} #{text}")
        send_line_msg("_sys", line)
      end
    end

    private def mark_connected : Nil
      return if @sent_connected_msg
      @sent_connected_msg = true
      send_line_msg("_sys", STYLE_DIM.render("-- connected to #{@server.address} --"))
      @dispatch.call(ConnectedMsg.new(@server.id))
      @server.channels.each { |ch| join(ch) }
    end

    private def send_line_msg(channel : String, line : String) : Nil
      @dispatch.call(IrcLineMsg.new(@server.id, channel, line))
    end

    private def send_line(line : String) : Nil
      io = @socket
      return unless io
      @write_lock.synchronize do
        io << line << "\r\n"
        io.flush
      end
    end

    private def dispatch_disconnect(error : Exception?) : Nil
      return if @dispatched_disconnect
      @dispatched_disconnect = true
      @dispatch.call(DisconnectedMsg.new(@server.id, error))
    end

    private def parse_host_port(address : String) : {String, Int32}
      if address.starts_with?("[")
        host, remainder = address.split("]", 2)
        port_str = remainder.lstrip(":")
        return {host.lstrip("["), port_str.to_i}
      end

      idx = address.rindex(":")
      raise ArgumentError.new("address must be host:port") unless idx
      host = address[0, idx]
      port_str = address[idx + 1, address.size - idx - 1]
      {host, port_str.to_i}
    end

    private def parse_irc_message(line : String) : IrcMessage
      rest = line
      prefix = nil

      if rest.starts_with?(":")
        parts = rest.split(" ", 2)
        prefix = parts[0][1..-1]
        rest = parts[1]? || ""
      end

      trailing = nil
      if idx = rest.index(" :")
        trailing = rest[(idx + 2)..-1]
        rest = rest[0, idx]
      end

      parts = rest.split(" ").reject(&.empty?)
      command = parts.shift? || ""
      params = parts
      params << trailing.not_nil! if trailing
      IrcMessage.new(prefix, command, params)
    end

    private def dispatch_target(target : String) : String
      return target if target.starts_with?("#")
      "_sys"
    end

    private def nick_from_prefix(prefix : String?) : String
      return "" unless prefix
      prefix.split("!", 2)[0]
    end

    private def action_message?(text : String) : Bool
      text.starts_with?("\u0001ACTION ") && text.ends_with?("\u0001")
    end

    private def strip_action(text : String) : String
      text.gsub("\u0001ACTION ", "").gsub("\u0001", "")
    end

    private def numeric?(command : String) : Bool
      command.to_i?.is_a?(Int32)
    end

    private def timestamp : String
      Time.local.to_s("%H:%M")
    end
  end

  class Model
    include Term2::Model

    @width : Int32
    @height : Int32
    @left_width : Int32
    @focus : Pane
    @mode : RightMode
    @server_list : TC::List
    @row_h : Int32
    @servers : Hash(ServerId, Server)
    @next_id : ServerId
    @form_inputs : Array(TC::TextInput)
    @form_sel : FormField
    @active_id : ServerId
    @active_chan : String
    @chat_vp : TC::Viewport
    @chat_input : TC::TextInput
    @header_lines : Int32
    @ready : Bool
    @list_items : Array(TC::List::Item)
    @dispatch : DispatchProc?

    def initialize
      @width = 0
      @height = 0
      @left_width = 24
      @focus = Pane::Right
      @mode = RightMode::Form
      @servers = Hash(ServerId, Server).new
      @next_id = 1
      @form_inputs = [] of TC::TextInput
      @form_sel = FormField::Name
      @active_id = 0
      @active_chan = ""
      @chat_vp = TC::Viewport.new(0, 0)
      @chat_input = TC::TextInput.new
      @header_lines = 2
      @ready = false
      @list_items = [] of TC::List::Item
      @dispatch = nil

      delegate = ServerListDelegate.new(ServerListStyles.new)
      @server_list = TC::List.new([] of TC::List::Item, 20, 10)
      @server_list.delegate = delegate
      @server_list.show_title = false
      @server_list.show_help = false
      @server_list.show_filter = false
      @server_list.filtering_enabled = false
      @server_list.show_pagination = false
      @server_list.show_status_bar = false

      @row_h = delegate.height + delegate.spacing

      build_form_inputs

      @chat_input.prompt = STYLE_PINK_B.render("> ")
      @chat_input.text_style = STYLE_PINK
      @chat_input.placeholder = "Type message or /command..."

      @list_items << AddServerItem.new.as(TC::List::Item)
      @server_list.items = @list_items
    end

    def attach_dispatcher(dispatcher : DispatchProc) : Nil
      @dispatch = dispatcher
    end

    def init : Term2::Cmd
      focus_form_field(@form_sel.to_i)
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::WindowSizeMsg
        resize(msg.width, msg.height)
        return {self, Term2::Cmds.none}
      when Term2::KeyMsg
        key = msg.key.to_s
        case key
        when "ctrl+c", "esc"
          return {self, Term2::Cmds.quit}
        when "left"
          @focus = Pane::Servers
          blur_right
          return {self, Term2::Cmds.none}
        when "right"
          @focus = Pane::Right
          focus_right
          return {self, Term2::Cmds.none}
        end

        if @focus == Pane::Servers
          return update_servers_pane(msg)
        end

        return update_right_pane(msg)
      when IrcLineMsg
        apply_chan_line(msg)
        return {self, Term2::Cmds.none}
      when ConnectedMsg
        handle_connected(msg)
        return {self, Term2::Cmds.none}
      when DisconnectedMsg
        handle_disconnected(msg)
        return {self, Term2::Cmds.none}
      when ErrMsg
        Log.debug { "zuse error: #{msg.error.message}" }
        return {self, Term2::Cmds.none}
      end

      {self, Term2::Cmds.none}
    end

    def view : String
      return "loading..." unless @ready

      top_padding = 2
      servers_title = STYLE_DIM.render("Servers List")

      left_inner = Term2.join_vertical(
        Term2::Position::Left,
        TITLE_STYLE.render("zuse irc beta"),
        Term2::Style.new.margin_top(1).margin_bottom(1).render(servers_title),
        @server_list.view
      )

      left_box = BOX_STYLE.width(@left_width).height(@height - top_padding).render(left_inner)
      right_inner = @mode == RightMode::Form ? view_form : view_chat
      right_box = BOX_STYLE.width(@width - @left_width - 4).height(@height - top_padding).render(right_inner)

      spacer = Term2::Style.new.width(2).height(@height - top_padding).render(" ")
      joined = Term2.join_horizontal(Term2::Position::Top, left_box, right_box, spacer)
      top_spacer = Term2::Style.new.width(@width).height(top_padding).render(" ")
      final_view = Term2.join_vertical(Term2::Position::Left, top_spacer, joined)

      Term2.place(@width, @height, Term2::Position::Left, Term2::Position::Top, final_view)
    end

    private def build_form_inputs : Nil
      @form_inputs = Array(TC::TextInput).new

      new_input = ->(placeholder : String) do
        input = TC::TextInput.new
        input.placeholder = placeholder
        input.prompt = STYLE_PINK_B.render(" > ")
        input.text_style = STYLE_PINK
        input
      end

      @form_inputs << new_input.call("Friendly name (e.g. Rekt)")
      @form_inputs << new_input.call("irc.example.net:6697")
      @form_inputs << new_input.call("TLS? (true/false)")
      @form_inputs << new_input.call("MySuperNickname")
      @form_inputs << new_input.call("#chan1,#chan2")
      @form_inputs << new_input.call("")
    end

    private def resize(width : Int32, height : Int32) : Nil
      @width = width
      @height = height

      left_inner_w = @left_width - 2
      right_inner_w = (@width - @left_width) - 2
      inner_h = @height - 2

      @form_inputs.each do |input|
        input.width = right_inner_w - 4
      end

      list_h = calc_list_height(inner_h - 4)
      @server_list.width = left_inner_w - 2
      @server_list.height = list_h

      @header_lines = 2
      chat_reserved = @header_lines + 1 + 1
      @chat_vp.width = right_inner_w - 2
      @chat_vp.height = inner_h - chat_reserved - 1
      @chat_input.width = @chat_vp.width

      @ready = true
      flush_queued
      refresh_chat if @mode == RightMode::Chat && @active_id != 0
    end

    private def flush_queued : Nil
      @servers.each_value do |server|
        server.queued.each { |queued| apply_chan_line(queued) }
        server.queued.clear
      end
    end

    private def calc_list_height(avail : Int32) : Int32
      n = @list_items.size
      n = 1 if n == 0
      h = (n * @row_h) + 1
      h = avail if h > avail
      h = @row_h + 1 if h < @row_h + 1
      h
    end

    private def resize_list : Nil
      left_inner_w = @left_width - 2
      inner_h = @height - 2
      list_h = calc_list_height(inner_h - 4)
      @server_list.width = left_inner_w - 2
      @server_list.height = list_h
    end

    private def update_servers_pane(key : Term2::KeyMsg) : {Term2::Model, Term2::Cmd}
      case key.key.to_s
      when "enter"
        return {self, Term2::Cmds.none} if @list_items.empty?

        case selected = @server_list.selected_item
        when ServerListItem
          @active_id = selected.id
          @active_chan = selected.channel.empty? ? "_sys" : selected.channel

          server = @servers[selected.id]?
          return {self, Term2::Cmds.none} unless server

          cmds = [] of Term2::Cmd?
          if server.client.nil? || !server.connected
            cmds << connect_server_cmd(server.id)
          elsif !selected.channel.empty? && !server.joined.includes?(selected.channel)
            server.client.try(&.join(selected.channel))
            server.joined.add(selected.channel)
          end

          @mode = RightMode::Chat
          @focus = Pane::Right
          focus_right
          refresh_chat
          return {self, Term2::Cmds.batch(cmds)}
        when AddServerItem
          @mode = RightMode::Form
          @focus = Pane::Right
          clear_form
          focus_right
          return {self, Term2::Cmds.none}
        end
      when "a"
        @mode = RightMode::Form
        @focus = Pane::Right
        clear_form
        focus_right
        return {self, Term2::Cmds.none}
      when "d"
        remove_selected_server
        return {self, Term2::Cmds.none}
      end

      @server_list, cmd = @server_list.update(key)
      {self, cmd}
    end

    private def update_right_pane(key : Term2::KeyMsg) : {Term2::Model, Term2::Cmd}
      case @mode
      when RightMode::Form
        update_form(key)
      when RightMode::Chat
        update_chat(key)
      else
        {self, Term2::Cmds.none}
      end
    end

    private def update_form(key : Term2::KeyMsg) : {Term2::Model, Term2::Cmd}
      case key.key.to_s
      when "up"
        return {self, focus_form_field(@form_sel.to_i - 1)} if @form_sel.to_i > 0
      when "down"
        return {self, focus_form_field(@form_sel.to_i + 1)} if @form_sel.to_i < FormField.values.size - 1
      when "enter"
        if @form_sel != FormField::Submit
          return {self, focus_form_field(@form_sel.to_i + 1)}
        end

        cfg = form_config
        unless cfg
          @form_inputs[FormField::Submit.to_i].set_value("error: name and address required")
          return {self, Term2::Cmds.none}
        end

        return {self, add_server(cfg)}
      end

      unless @form_sel == FormField::Submit
        input = @form_inputs[@form_sel.to_i]
        @form_inputs[@form_sel.to_i], cmd = input.update(key)
        return {self, cmd}
      end

      {self, Term2::Cmds.none}
    end

    private def update_chat(key : Term2::KeyMsg) : {Term2::Model, Term2::Cmd}
      case key.key.to_s
      when "up"
        @chat_vp.line_up
        return {self, Term2::Cmds.none}
      when "down"
        @chat_vp.line_down
        return {self, Term2::Cmds.none}
      when "pgup"
        @chat_vp.half_page_up
        return {self, Term2::Cmds.none}
      when "pgdown"
        @chat_vp.half_page_down
        return {self, Term2::Cmds.none}
      when "enter"
        text = @chat_input.value.strip
        return {self, Term2::Cmds.none} if text.empty?

        @chat_input.reset
        server = @servers[@active_id]?
        return {self, Term2::Cmds.none} unless server

        if text.starts_with?("/")
          return {self, handle_slash(server, text)}
        end

        if @active_chan.empty? || @active_chan == "_sys"
          push_sys_line(server.id, "_sys", "-- no channel selected, use /join #chan or select an item --")
          refresh_chat
          return {self, Term2::Cmds.none}
        end

        server.client.try(&.message(@active_chan, text))
        line = STYLE_DARK_PINK.render("[#{timestamp}] <#{server.nick}> #{text}")
        apply_chan_line(IrcLineMsg.new(server.id, @active_chan, line))
        return {self, Term2::Cmds.none}
      end

      @chat_input, cmd = @chat_input.update(key)
      {self, cmd}
    end

    private def view_form : String
      labels = [
        " Custom Server Name ",
        " Server:Port ",
        " TLS ",
        " Nick / Username / Real ",
        " Channels (comma) ",
        " SUBMIT ",
      ]

      builder = String::Builder.new
      builder << STYLE_PINK_B.render("  Add New IRC Connection") << "\n\n"

      FormField.values.each_with_index do |field, index|
        label = labels[index]
        if field == @form_sel && @focus == Pane::Right
          label = STYLE_DARK_SEL.render(label)
        else
          label = STYLE_PINK.render(label)
        end

        if field == FormField::Submit
          builder << label << "\n\n"
        else
          builder << label << "\n"
          builder << @form_inputs[index].view << "\n\n"
        end
      end

      builder << STYLE_DIM.render("up/down fields | Enter submit | left/right panes")
      builder.to_s
    end

    private def view_chat : String
      header = String::Builder.new
      title = "Chat"
      if server = @servers[@active_id]?
        stat = server.connected ? "*" : "o"
        chan_label = @active_chan.empty? || @active_chan == "_sys" ? "(system)" : @active_chan
        title = "#{stat} #{server.name} (#{server.nick}) #{chan_label}"
      end

      header << STYLE_PINK_B.render(title) << "\n"
      header << TITLE_STYLE.render("up/down scroll | left/right panes") << "\n"
      divider = STYLE_PINK.render("-" * @chat_vp.width)

      Term2.join_vertical(
        Term2::Position::Left,
        header.to_s + @chat_vp.view,
        divider,
        @chat_input.view
      )
    end

    private def focus_form_field(idx : Int32) : Term2::Cmd
      new_idx = idx.clamp(0, FormField.values.size - 1)

      if @form_sel != FormField::Submit
        @form_inputs[@form_sel.to_i].blur
      end

      @form_sel = FormField.values[new_idx]
      return Term2::Cmds.none if @form_sel == FormField::Submit

      Term2::Cmds.batch(@form_inputs[@form_sel.to_i].focus, @form_inputs[@form_sel.to_i].blink)
    end

    private def focus_right : Nil
      case @mode
      when RightMode::Form
        @form_inputs.each(&.blur)
        @form_inputs[@form_sel.to_i].focus if @form_sel != FormField::Submit
      when RightMode::Chat
        @chat_input.focus
      end
    end

    private def blur_right : Nil
      case @mode
      when RightMode::Form
        @form_inputs.each(&.blur)
      when RightMode::Chat
        @chat_input.blur
      end
    end

    private def clear_form : Nil
      @form_inputs.each do |input|
        input.set_value("")
        input.blur
      end
      @form_sel = FormField::Name
      @form_inputs[@form_sel.to_i].focus
    end

    private def form_config : {String, String, Bool, String, Array(String)}?
      name = @form_inputs[FormField::Name.to_i].value.strip
      addr = @form_inputs[FormField::Address.to_i].value.strip
      return if name.empty? || addr.empty?

      tls_str = @form_inputs[FormField::Tls.to_i].value.strip.downcase
      tls = ["true", "1", "yes"].includes?(tls_str)
      nick = @form_inputs[FormField::Nick.to_i].value.strip
      nick = "zuse" if nick.empty?

      channels = [] of String
      raw_channels = @form_inputs[FormField::Channels.to_i].value
      raw_channels.split(",").each do |chan|
        trimmed = chan.strip
        channels << trimmed unless trimmed.empty?
      end

      {name, addr, tls, nick, channels}
    end

    private def add_server(cfg : {String, String, Bool, String, Array(String)}) : Term2::Cmd
      name, addr, tls, nick, channels = cfg
      id = @next_id
      @next_id += 1

      server = Server.new(id, name, addr, tls, nick, channels)
      @servers[id] = server
      inject_ascii_art(server)

      if channels.empty?
        add_list_item(ServerListItem.new(id, name, addr, ""))
      else
        channels.each do |channel|
          add_list_item(ServerListItem.new(id, "#{name} - #{channel}", addr, channel))
        end
      end

      @active_id = id
      @active_chan = channels.empty? ? "_sys" : channels.first
      @mode = RightMode::Chat
      @focus = Pane::Right
      focus_right
      cmds = [] of Term2::Cmd?
      cmds << connect_server_cmd(id)
      cmds << @chat_input.blink
      Term2::Cmds.batch(cmds)
    end

    private def add_list_item(item : ServerListItem) : Nil
      exists = @list_items.any? do |existing|
        next false unless existing.is_a?(ServerListItem)
        entry = existing.as(ServerListItem)
        entry.id == item.id && entry.channel == item.channel
      end
      return if exists

      @list_items.reject! { |existing| existing.is_a?(AddServerItem) }
      @list_items << item
      @list_items << AddServerItem.new.as(TC::List::Item)
      @server_list.items = @list_items
      resize_list
    end

    private def remove_selected_server : Nil
      selected = @server_list.selected_item
      return unless selected.is_a?(ServerListItem)

      id = selected.as(ServerListItem).id
      if server = @servers[id]?
        server.client.try(&.quit("bye"))
        server.client.try(&.close)
      end

      @servers.delete(id)
      @list_items.reject! do |item|
        item.is_a?(ServerListItem) && item.as(ServerListItem).id == id
      end
      @list_items.reject! { |item| item.is_a?(AddServerItem) }
      @list_items << AddServerItem.new.as(TC::List::Item)
      @server_list.items = @list_items
      resize_list

      if @active_id == id
        @mode = RightMode::Form
        @active_id = 0
        @active_chan = ""
      end
    end

    private def handle_slash(server : Server, raw : String) : Term2::Cmd
      parts = raw.lstrip('/').split(" ", 2)
      command = parts[0].downcase
      arg = parts[1]? || ""

      log_sys = ->(text : String) do
        push_sys_line(server.id, @active_chan, text)
        refresh_chat
      end

      case command
      when "join"
        if arg.empty?
          log_sys.call("usage: /join #chan")
          return Term2::Cmds.none
        end

        server.client.try(&.join(arg))
        server.channels << arg unless server.channels.includes?(arg)
        server.joined.add(arg)
        server.channel_logs[arg] ||= [] of String
        server.channel_logs[arg] << STYLE_DIM.render("-- joined #{arg} --")

        add_list_item(ServerListItem.new(server.id, "#{server.name} - #{arg}", server.address, arg))
        log_sys.call("-- joined #{arg} --")
      when "nick"
        if arg.empty?
          log_sys.call("usage: /nick newnick")
          return Term2::Cmds.none
        end
        server.client.try(&.nick(arg))
        log_sys.call("-- nick change requested: #{arg}")
      when "quit"
        server.client.try(&.quit("bye"))
      when "msg"
        parts = arg.split(" ", 2)
        if parts.size < 2
          log_sys.call("usage: /msg target text")
          return Term2::Cmds.none
        end
        target = parts[0]
        text = parts[1]
        server.client.try(&.message(target, text))
        log_sys.call("[to #{target}] #{text}")
      else
        log_sys.call("unknown command: #{command}")
      end

      Term2::Cmds.none
    end

    private def connect_server_cmd(id : ServerId) : Term2::Cmd?
      dispatcher = @dispatch
      return unless dispatcher
      server = @servers[id]?
      return unless server

      -> do
        if server.client.nil?
          server.client = IrcClient.new(server, dispatcher)
        end
        spawn { server.client.try(&.connect) }
        nil.as(Term2::Msg?)
      end
    end

    private def inject_ascii_art(server : Server) : Nil
      art = <<-ART
  ____  ____  ____  ____
 / __ \\/ __ \\/ __ \\/ __ \\
/ / / / / / / / / / /_/ /
\\ \\_\\ \\ \\_\\ \\ \\_\\ \\__,_/
 \\____/\\____/\\____/____/

  BABYWAREZ INTERNATIONAL, ALL RIGHTS DEREZZED

  joining...
ART

      line = STYLE_DIM.render(art)
      server.channel_logs["_sys"] ||= [] of String
      server.channel_logs["_sys"] << line
      server.channels.each do |channel|
        server.channel_logs[channel] ||= [] of String
        server.channel_logs[channel] << line
      end
    end

    private def apply_chan_line(msg : IrcLineMsg) : Nil
      unless @ready
        if server = @servers[msg.server_id]?
          server.queued << msg
        end
        return
      end

      server = @servers[msg.server_id]?
      return unless server

      channel = msg.channel.empty? ? "_sys" : msg.channel
      server.channel_logs[channel] ||= [] of String
      server.channel_logs[channel] << msg.line

      refresh_chat if @mode == RightMode::Chat && @active_id == msg.server_id && @active_chan == channel
    end

    private def push_sys_line(id : ServerId, channel : String, text : String) : Nil
      server = @servers[id]?
      return unless server

      chan = channel.empty? ? "_sys" : channel
      server.channel_logs[chan] ||= [] of String
      server.channel_logs[chan] << STYLE_DIM.render(text)
    end

    private def refresh_chat : Nil
      server = @servers[@active_id]?
      return unless server
      logs = server.channel_logs[@active_chan]? || [] of String

      width = @chat_vp.width
      width = 80 if width <= 0

      wrapper = Term2::Style.new.width(width)
      wrapped = logs.map { |line| wrapper.render(line) }.join("\n")
      @chat_vp.content = wrapped
      @chat_vp.goto_bottom
    end

    private def handle_connected(msg : ConnectedMsg) : Nil
      server = @servers[msg.server_id]?
      return unless server
      server.connected = true
      push_sys_line(server.id, "", "-- connected --")
      refresh_chat if @mode == RightMode::Chat && @active_id == server.id
    end

    private def handle_disconnected(msg : DisconnectedMsg) : Nil
      server = @servers[msg.server_id]?
      return unless server
      server.connected = false
      text = "-- disconnected --"
      if msg.error
        text += " (#{msg.error.not_nil!.message})"
      end
      push_sys_line(server.id, "", text)
      refresh_chat if @mode == RightMode::Chat && @active_id == server.id
    end

    private def timestamp : String
      Time.local.to_s("%H:%M")
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  model = ZuseApp::Model.new
  options = Term2::ProgramOptions.new(Term2::WithAltScreen.new)
  program = Term2::Program(ZuseApp::Model).new(model, options: options)
  model.attach_dispatcher(->(msg : Term2::Message) { program.dispatch(msg) })
  program.run
end
