require "../../../src/term2"
require "./random_items"

include Term2::Prelude

STATUS_COLOR = Term2::AdaptiveColor.new(
  light: Term2::Color.from_hex("#04B575"),
  dark: Term2::Color.from_hex("#04B575"),
)

class FancyItem
  include TC::List::Item
  getter title : String
  getter description : String

  def initialize(@title : String, @description : String)
  end

  def filter_value : String
    @title
  end
end

class DelegateKeys
  TC::Key.key_bindings(
    choose: {["enter"], "enter", "choose"},
    remove: {["x", "backspace"], "x", "delete"},
  )
end

class FancyDelegate
  include TC::List::ItemDelegate

  getter key_map : DelegateKeys
  getter remove_enabled : Bool
  getter update_status : Proc(String, Term2::Cmd)

  def initialize(@key_map = DelegateKeys.new)
    @remove_enabled = true
    @update_status = ->(_s : String) : Term2::Cmd { -> { nil.as(Term2::Message?) } }
  end

  def update_status=(proc : Proc(String, Term2::Cmd))
    @update_status = proc
  end

  def height : Int32
    2
  end

  def spacing : Int32
    1
  end

  def render(io : IO, item : TC::List::Item, index : Int32, selected : Bool, enumerator : String)
    fi = item.as(FancyItem)
    title = fi.title
    desc = fi.description

    title_style = selected ? Term2::Style.new.foreground(Term2::Color::GREEN) : Term2::Style.new
    cursor = selected ? "> " : "  "
    enum_str = enumerator.empty? ? "" : "#{enumerator} "

    io << title_style.render("#{cursor}#{enum_str}#{title}") << "\n"
    io << Term2::Style.new.faint(true).render("    #{desc}")
  end

  def update(msg : Term2::Msg, model : TC::List) : Term2::Cmd
    case msg
    when Term2::KeyMsg
      case
      when @key_map.choose.matches?(msg)
        if selected = model.selected_item
          title = selected.as(FancyItem).title
          return status_cmd("You chose #{title}")
        end
      when @key_map.remove.matches?(msg)
        return Term2::Cmds.none unless @remove_enabled
        index = model.index
        if item = model.items[index]?
          model.items.delete_at(index)
          model.update_pagination
          @remove_enabled = false if model.items.empty?
          return status_cmd("Deleted #{item.as(FancyItem).title}")
        end
      end
    end
    Term2::Cmds.none
  end

  private def status_cmd(text : String) : Term2::Cmd
    @update_status.call(text)
  end
end

class FancyListKeys
  TC::Key.key_bindings(
    insert_item:       {["a"], "a", "add item"},
    toggle_spinner:    {["s"], "s", "toggle spinner"},
    toggle_title_bar:  {["T"], "T", "toggle title"},
    toggle_status_bar: {["S"], "S", "toggle status"},
    toggle_pagination: {["P"], "P", "toggle pagination"},
    toggle_help_menu:  {["H"], "H", "toggle help"},
  )
end

class FancyListModel
  include Term2::Model

  APP_STYLE   = Term2::Style.new.padding(1, 2)
  TITLE_STYLE = Term2::Style.new.foreground(Term2::Color.from_hex("#FFFDF5")).background(Term2::Color.from_hex("#25A065")).padding(0, 1)

  getter list : TC::List
  getter item_generator : RandomItemGenerator
  getter keys : FancyListKeys
  getter delegate_keys : DelegateKeys

  def initialize
    generator = RandomItemGenerator.new
    items = Array(TC::List::Item).new
    24.times { items << generator.next.as(TC::List::Item) }

    @delegate_keys = DelegateKeys.new
    delegate = FancyDelegate.new(@delegate_keys)
    @keys = FancyListKeys.new
    @item_generator = generator

    @list = TC::List.new(items, 0, 0)
    @list.delegate = delegate
    @list.title = "Groceries"
    @list.show_help = true
    @list.show_pagination = true
    @list.show_status_bar = true
    @list.show_filter = true
    @list.filtering_enabled = true

    delegate.update_status = ->(text : String) : Term2::Cmd {
      @list.status_message = status_message(text)
      -> { nil.as(Term2::Message?) }
    }

    # Additional help bindings
    @list.additional_full_help_keys = -> {
      [
        @keys.toggle_spinner,
        @keys.insert_item,
        @keys.toggle_title_bar,
        @keys.toggle_status_bar,
        @keys.toggle_pagination,
        @keys.toggle_help_menu,
      ]
    }
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      h = APP_STYLE.get_horizontal_margins + APP_STYLE.get_horizontal_padding
      v = APP_STYLE.get_vertical_margins + APP_STYLE.get_vertical_padding
      @list.width = msg.width - h
      @list.height = msg.height - v
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        return {self, Term2::Cmds.quit}
      end

      if @list.filter_state == TC::List::FilterState::Filtering
        # let list handle filtering keys
      else
        case
        when @keys.toggle_spinner.matches?(msg)
          return {self, nil} # spinner not implemented; no-op
        when @keys.toggle_title_bar.matches?(msg)
          v = !@list.show_title?
          @list.show_title = v
          @list.show_filter = v
          @list.filtering_enabled = v
          return {self, nil}
        when @keys.toggle_status_bar.matches?(msg)
          @list.show_status_bar = !@list.show_status_bar?
          return {self, nil}
        when @keys.toggle_pagination.matches?(msg)
          @list.show_pagination = !@list.show_pagination?
          return {self, nil}
        when @keys.toggle_help_menu.matches?(msg)
          @list.show_help = !@list.show_help?
          return {self, nil}
        when @keys.insert_item.matches?(msg)
          @delegate_keys.remove.enabled = true
          new_item = @item_generator.next
          @list.items.insert(0, new_item)
          @list.update_pagination
          @list.status_message = status_message("Added #{new_item.title}")
          return {self, nil}
        end
      end
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : String
    APP_STYLE.render(@list.view)
  end

  private def status_message(text : String) : String
    Term2::Style.new.foreground(STATUS_COLOR).render(text)
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(FancyListModel.new, options: Term2::ProgramOptions.new(Term2::WithAltScreen.new))
end
