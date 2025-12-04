require "../../../src/term2"
require "http/client"
require "json"
require "log"

include Term2::Prelude
alias TC = Term2::Components

Log.setup_from_env

REPOS_URL           = "https://api.github.com/orgs/charmbracelet/repos"
DEFAULT_SUGGESTIONS = ["bubbletea", "bubbles", "lipgloss", "huh", "wish", "soft-serve", "huh", "glow", "gum"]

struct Repo
  include JSON::Serializable
  getter name : String
end

class GotReposSuccessMsg < Term2::Message
  getter repos : Array(Repo)

  def initialize(@repos : Array(Repo)); end
end

class GotReposErrMsg < Term2::Message
  getter err : Exception

  def initialize(@err : Exception); end
end

class Keymap
  include TC::Help::KeyMap

  getter complete : TC::Key::Binding
  getter next : TC::Key::Binding
  getter prev : TC::Key::Binding
  getter quit : TC::Key::Binding

  def initialize
    @complete = TC::Key::Binding.new(["tab"], "tab", "complete")
    @next = TC::Key::Binding.new(["ctrl+n"], "ctrl+n", "next")
    @prev = TC::Key::Binding.new(["ctrl+p"], "ctrl+p", "prev")
    @quit = TC::Key::Binding.new(["esc", "ctrl+c"], "esc", "quit")
  end

  def short_help : Array(TC::Key::Binding)
    [@complete, @next, @prev, @quit]
  end

  def full_help : Array(Array(TC::Key::Binding))
    [short_help]
  end
end

class AutocompleteModel
  include Model

  getter text_input : TC::TextInput
  getter help : TC::Help
  getter keymap : Keymap
  getter status : String?

  def initialize
    @text_input = TC::TextInput.new("autocomplete-input")
    @text_input.placeholder = "repository"
    @text_input.prompt = "charmbracelet/"
    @text_input.prompt_style = Term2::Style.new.foreground(Term2::Color::CYAN)
    @text_input.cursor.style = Term2::Style.new.foreground(Term2::Color::CYAN)
    @text_input.focus
    @text_input.char_limit = 50
    @text_input.width = 30
    @text_input.show_suggestions = true
    @text_input.set_suggestions(DEFAULT_SUGGESTIONS)

    @help = TC::Help.new
    @keymap = Keymap.new
    @status = nil
  end

  def init : Cmd
    Cmds.batch(@text_input.focus, fetch_repos_cmd, @text_input.cursor.blink_cmd)
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "enter", "ctrl+c", "esc"
        return {self, Cmds.quit}
      when "tab"
        @text_input.accept_current_suggestion
      when "ctrl+n"
        @text_input.next_suggestion
      when "ctrl+p"
        @text_input.prev_suggestion
      end
    when GotReposSuccessMsg
      @text_input.set_suggestions(msg.repos.map(&.name))
      @text_input.show_suggestions = true
      @status = nil
    when GotReposErrMsg
      @status = "Failed to load repos: #{msg.err.message}"
    end

    new_input, cmd = @text_input.update(msg)
    @text_input = new_input
    {self, cmd}
  end

  def view : String
    String.build do |str|
      str << "Pick a Charm™ repo:\n\n  "
      str << @text_input.view
      str << "\n\n"
      str << @help.view(@keymap)
      str << "\n"
      if status = @status
        str << "\n" << status
      end
      str << "\n"
    end
  end

  private def fetch_repos_cmd : Cmd
    -> : Term2::Msg? do
      begin
        headers = HTTP::Headers{
          "Accept"               => "application/vnd.github+json",
          "X-GitHub-Api-Version" => "2022-11-28",
          "User-Agent"           => "term2-autocomplete",
        }
        response = HTTP::Client.get(REPOS_URL, headers: headers)
        if response.status.success?
          repos = Array(Repo).from_json(response.body)
          GotReposSuccessMsg.new(repos)
        else
          GotReposErrMsg.new(RuntimeError.new("status #{response.status_code}"))
        end
      rescue ex
        GotReposErrMsg.new(ex)
      end
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(AutocompleteModel.new)
end
