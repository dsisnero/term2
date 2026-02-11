require "../../../lib/charmtone/src/charmtone"
require "../../../src/term2"
require "../../../src/components/text_input"

module IsbnFormExample
  include Term2::Prelude

  INPUT_STYLE    = Lipgloss::Style.new.foreground(Lipgloss::Color.hex(Charmtone::Key::Tang.hex))
  CONTINUE_STYLE = Lipgloss::Style.new.foreground(Lipgloss::Color.hex(Charmtone::Key::Anchovy.hex))
  VALID_STYLE    = Lipgloss::Style.new.foreground(Lipgloss::Color.hex(Charmtone::Key::Guac.hex))
  ERR_STYLE      = Lipgloss::Style.new.foreground(Lipgloss::Color.hex(Charmtone::Key::Cherry.hex))

  BANNED_TITLE_WORDS = {
    "very", "bad", "words", "that", "should",
    "not", "appear", "in", "book", "titles",
  }

  class Model
    include Term2::Model

    getter isbn_input : Term2::Components::TextInput
    getter title_input : Term2::Components::TextInput
    getter focused_input : Int32
    property err : Exception? = nil

    def initialize
      @isbn_input = Term2::Components::TextInput.new
      @isbn_input.focus
      @isbn_input.placeholder = "978-X-XXX-XXXXX-X"
      @isbn_input.char_limit = 17
      @isbn_input.width = 30
      @isbn_input.prompt = ""
      @isbn_input.validate = ->isbn13_validator(String)

      @title_input = Term2::Components::TextInput.new
      @title_input.blur
      @title_input.placeholder = "Title"
      @title_input.char_limit = 100
      @title_input.width = 100
      @title_input.prompt = ""
      @title_input.validate = ->book_title_validator(String)

      @focused_input = 0
    end

    def init : Term2::Cmd
      Term2::Components::TextInput.blink
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        case msg.string
        when "up", "down"
          if @focused_input == 0
            @focused_input = 1
            @title_input.focus
            @isbn_input.blur
          else
            @focused_input = 0
            @isbn_input.focus
            @title_input.blur
          end
        when "enter"
          return {self, Term2.quit} if can_find_book?
        when "ctrl+c", "esc"
          return {self, Term2.quit}
        end
      when Exception
        @err = msg
        return {self, nil}
      end

      @isbn_input, isbn_cmd = @isbn_input.update(msg)
      @title_input, title_cmd = @title_input.update(msg)
      {self, Term2::Cmds.batch(isbn_cmd, title_cmd)}
    end

    def view : Term2::View
      continue_text = can_find_book? ? CONTINUE_STYLE.render("Find ->") : ""
      isbn_error_text = validation_status_text(@isbn_input, "Valid ISBN")
      title_error_text = validation_status_text(@title_input, "Valid title")

      content = <<-TXT
       Search book:
       #{INPUT_STYLE.width(30).render("ISBN")}
       #{@isbn_input.view.content}
       #{isbn_error_text}

       #{INPUT_STYLE.width(30).render("Title")}
       #{@title_input.view.content}
       #{title_error_text}

       #{continue_text}

      TXT

      Term2::View.new(content: content + "\n")
    end

    def can_find_book? : Bool
      correct_isbn = @isbn_input.err.nil? && !@isbn_input.value.empty?
      correct_title = @title_input.err.nil? && !@title_input.value.empty?
      correct_isbn && correct_title
    end

    private def validation_status_text(input : Term2::Components::TextInput, ok_text : String) : String
      return "" if input.value.empty?
      if err = input.err
        ERR_STYLE.render(err.message || "invalid input")
      else
        VALID_STYLE.render(ok_text)
      end
    end

    private def isbn13_validator(value : String) : Exception?
      s = value.gsub("-", "")
      return Exception.new("ISBN is of wrong length") unless s.size == 13
      return Exception.new("ISBN contains invalid characters") unless s.each_char.all?(&.ascii_number?)

      prefix = s[0, 3]
      return Exception.new("ISBN has invalid GS1 prefix") unless prefix == "978" || prefix == "979"

      sum = 0
      s.each_char_with_index do |ch, idx|
        n = ch.ord - '0'.ord
        n *= 3 if idx.odd?
        sum += n
      end
      return Exception.new("ISBN has invalid check digit") unless (sum % 10) == 0
      nil
    end

    private def book_title_validator(value : String) : Exception?
      s = value.strip
      return Exception.new("Book title is empty") if s.empty?

      BANNED_TITLE_WORDS.each do |word|
        return Exception.new(%(Book title contains banned word "#{word}")) if s.includes?(word)
      end
      nil
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(IsbnFormExample::Model.new)
end
