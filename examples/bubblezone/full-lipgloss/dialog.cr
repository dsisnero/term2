require "./styles"

class DialogComponent
  getter id : String
  getter question : String
  property active : String = "confirm"

  def initialize(@question : String = "Are you sure you want to eat marmalade?")
    @id = Term2::Zone.new_prefix + "dialog_"
  end

  def handle_zone_click(msg : Term2::ZoneClickMsg) : Bool
    return false unless msg.id.starts_with?(@id)
    clicked = msg.id[@id.size..-1]
    if ["confirm", "cancel"].includes?(clicked)
      @active = clicked
      true
    else
      false
    end
  end

  def view(width : Int32, _height : Int32) : String
    question = BubblezoneFullLipgloss.dialog_question(@question)
    confirm = BubblezoneFullLipgloss.dialog_button("#{@id}confirm", "Yes", @active == "confirm")
    cancel = BubblezoneFullLipgloss.dialog_button("#{@id}cancel", "Maybe", @active == "cancel")
    buttons = Term2.join_horizontal(Term2::Position::Top, confirm, cancel)
    BubblezoneFullLipgloss.dialog_box([question, buttons].join("\n"), width)
  end
end
