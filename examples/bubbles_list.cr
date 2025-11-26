require "../src/term2"
require "../src/bubbles/list"

class ListModel < Term2::Model
  property list : Term2::Bubbles::List

  def initialize
    @list = Term2::Bubbles::List.new(
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
end

class ListDemo < Term2::Application(ListModel)
  def init : {ListModel, Term2::Cmd}
    {ListModel.new, Term2::Cmd.none}
  end

  def update(msg : Term2::Message, model : ListModel) : {ListModel, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      if msg.key.to_s == "q" || msg.key.to_s == "ctrl+c"
        return {model, Term2::Cmd.quit}
      end
    end

    new_list, cmd = model.list.update(msg)
    model.list = new_list

    {model, cmd}
  end

  def view(model : ListModel) : String
    "Select a board:\n\n" +
      model.list.view +
      "\n(q to quit)"
  end
end

ListDemo.new.run
