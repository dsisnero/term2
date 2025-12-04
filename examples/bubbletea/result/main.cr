require "../../../src/term2"

include Term2::Prelude

CHOICES = ["Taro", "Coffee", "Lychee"]

class ResultModel
  include Term2::Model

  getter cursor : Int32
  getter choice : String

  def initialize
    @cursor = 0
    @choice = ""
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "q", "esc"
        return {self, Term2::Cmds.quit}
      when "enter"
        @choice = CHOICES[@cursor]
        return {self, Term2::Cmds.quit}
      when "down", "j"
        @cursor += 1
        @cursor = 0 if @cursor >= CHOICES.size
      when "up", "k"
        @cursor -= 1
        @cursor = CHOICES.size - 1 if @cursor < 0
      end
    end
    {self, nil}
  end

  def view : String
    String.build do |s|
      s << "What kind of Bubble Tea would you like to order?\n\n"
      CHOICES.each_with_index do |c, i|
        s << (i == @cursor ? "(•) " : "( ) ")
        s << c << "\n"
      end
      s << "\n(press q to quit)\n"
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  model = Term2.run(ResultModel.new)
  if model.is_a?(ResultModel) && !model.choice.empty?
    puts "\n---\nYou chose #{model.choice}!"
  end
end
