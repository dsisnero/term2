require "../src/term2"
require "../src/components/list"
include Term2::Prelude

class ListModel < Term2::Model
  property list : TC::List

  def initialize
    @list = TC::List.new(
      items: [
        {"Raspberry Pi", "Tiny computer"},
        {"Arduino", "Microcontroller"},
        {"ESP32", "WiFi + Bluetooth"},
        {"Teensy", "High performance"},
        {"STM32", "Industry standard"},
      ],
      width: 20,
      height: 10
    )
  end

  def init : Cmd
    Cmd.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {self, Term2.quit}
      end
    end

    new_list, cmd = @list.update(msg)
    @list = new_list

    {self, cmd}
  end

  def view : String
    "Select a board:\n\n" +
      @list.view +
      "\n(q to quit)"
  end
end

Term2.run(ListModel.new)
