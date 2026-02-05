require "../../../src/term2"
require "./styles"
require "./tabs"
require "./list"
require "./dialog"
require "./history"

include Term2::Prelude

module BubblezoneFullLipglossExample
  class FullLipglossModel
    include Model

    @width : Int32
    @height : Int32

    def initialize
      tabs_id = Term2::Zone.new_prefix
      list1_id = Term2::Zone.new_prefix
      list2_id = Term2::Zone.new_prefix
      dialog_id = Term2::Zone.new_prefix
      history_id = Term2::Zone.new_prefix

      @tabs = BubblezoneFullLipgloss::TabsComponent.new(
        tabs_id,
        ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"],
        "Lip Gloss"
      )

      @list1 = BubblezoneFullLipgloss::ListComponent.new(list1_id, "Citrus Fruits to Try", build_list(list_one_data))
      @list2 = BubblezoneFullLipgloss::ListComponent.new(list2_id, "Actual Lip Gloss Vendors", build_list(list_two_data))
      @dialog = BubblezoneFullLipgloss::DialogComponent.new(dialog_id)
      @history = BubblezoneFullLipgloss::HistoryComponent.new(history_id, history_data)
      @width = 0
      @height = 0
    end

    def init : Cmd
      Cmds.none
    end

    def update(msg : Message) : {Model, Cmd}
      unless initialized?
        return {self, Cmds.none} unless msg.is_a?(WindowSizeMsg)
      end

      case msg
      when KeyMsg
        handle_key(msg)
      when Term2::ZoneClickMsg
        return {self, Cmds.none} if @tabs.handle_zone_click(msg)
        return {self, Cmds.none} if @list1.handle_zone_click(msg)
        return {self, Cmds.none} if @list2.handle_zone_click(msg)
        return {self, Cmds.none} if @dialog.handle_zone_click(msg)
        return {self, Cmds.none} if @history.handle_zone_click(msg)
        {self, Cmds.none}
      when WindowSizeMsg
        @width = msg.width
        @height = msg.height
        {self, Cmds.none}
      else
        {self, Cmds.none}
      end
    end

    def view : String
      return "" unless initialized?

      inner_width = @width - 4 # padding(1,2,1,2)
      inner_height = @height - 2
      return "" if inner_width <= 0 || inner_height <= 0

      tabs_height = 3
      list_height = 8
      history_height = inner_height - (tabs_height + list_height)
      history_height = [history_height, 0].max

      lists = Lipgloss.join_horizontal(Lipgloss::Position::Top,
        @list1.view(inner_width, list_height),
        @list2.view(inner_width, list_height),
        @dialog.view(inner_width, list_height)
      )

      content = Lipgloss.join_vertical(Lipgloss::Position::Top,
        @tabs.view(inner_width),
        "",
        Lipgloss.place_horizontal(inner_width, Lipgloss::Position::Center, lists),
        @history.view(inner_width, history_height)
      )

      Lipgloss::Style.new
        .max_height(@height)
        .max_width(@width)
        .padding(1, 2, 1, 2)
        .render(content)
    end

    private def handle_key(msg : KeyMsg) : {Model, Cmd}
      case msg.key.to_s
      when "ctrl+c"
        {self, Term2.quit}
      when "ctrl+e"
        Term2::Zone.enabled = !Term2::Zone.enabled?
        {self, nil}
      else
        {self, Cmds.none}
      end
    end

    private def initialized? : Bool
      @width > 0 && @height > 0
    end

    private def build_list(data : Array(Tuple(String, Bool))) : Array(BubblezoneFullLipgloss::ListItem)
      data.map do |name, done|
        BubblezoneFullLipgloss::ListItem.new(name, done)
      end
    end

    private def list_one_data : Array(Tuple(String, Bool))
      [
        {"Grapefruit", true},
        {"Yuzu", false},
        {"Citron", false},
        {"Kumquat", true},
        {"Pomelo", false},
      ]
    end

    private def list_two_data : Array(Tuple(String, Bool))
      [
        {"Glossier", true},
        {"Claire's Boutique", true},
        {"Nyx", false},
        {"Mac", false},
        {"Milk", false},
      ]
    end

    private def history_data : Array(String)
      [
        "The Romans learned from the Greeks that quinces slowly cooked with honey would set when cool. Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum. Roman marmalade remained a luxury.",
        "Medieval quince preserves, known as cotignac, were made both clear and fruit pulp style with spices. In the 17th century, La Varenne offered recipes for both thick and clear cotignac, simplifying medieval seasonings.",
        "In 1524, Henry VIII received a box of marmalade from Mr. Hull of Exeter. It was probably solid quince paste from Portugal and became a favorite treat of Anne Boleyn and her ladies in waiting.",
      ]
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(BubblezoneFullLipglossExample::FullLipglossModel.new, options: Term2::ProgramOptions.new(
    Term2::WithAltScreen.new,
    Term2::WithMouseCellMotion.new
  ))
end
