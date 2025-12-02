require "../../../src/term2"
require "./styles"
require "./tabs"
require "./list"
require "./dialog"
require "./history"

include Term2::Prelude

DOC_STYLE = Term2::Style.new
  .margin(1, 2, 1, 2)
  .padding(1)
  .border(Term2::Border.rounded)
  .border_foreground(BubblezoneFullLipgloss::HIGHLIGHT)
  .background(BubblezoneFullLipgloss::SUBTLE)

class FullLipglossModel
  include Model

  @width : Int32
  @height : Int32

  def initialize
    @tabs = TabsComponent.new(
      ["Lip Gloss", "Blush", "Eye Shadow", "Mascara", "Foundation"],
      "Lip Gloss"
    )

    @list1 = ListComponent.new("Citrus Fruits to Try", build_list(list_one_data), "list1_")
    @list2 = ListComponent.new("Actual Lip Gloss Vendors", build_list(list_two_data), "list2_")
    @dialog = DialogComponent.new
    @history = HistoryComponent.new(history_data)
    width, height = Term2::Terminal.size
    @width = width
    @height = height
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
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
    return "" if @width <= 0 || @height <= 0

    usable_width = [@width - 4, 20].max
    usable_height = [@height - 4, 20].max
    dialog_width = 28
    list_slot = [usable_width - dialog_width - 4, 0].max
    preferred = list_slot // 2
    list_width = [[preferred, 16].max, list_slot].min
    list_width = [[list_width, 1].max, list_slot].min
    list_height = [[usable_height // 2, 6].max, usable_height].min
    history_height = 5

    layout = [
      @tabs.view(usable_width),
      "",
      Term2.join_horizontal(Term2::Position::Top,
        @list1.view(list_width, list_height),
        @list2.view(list_width, list_height),
        @dialog.view(dialog_width, list_height)
      ),
      "",
      @history.view(usable_width, history_height),
    ].join("\n")

    DOC_STYLE.render(layout)
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

  private def build_list(data : Array(Tuple(String, Bool))) : Array(ListItem)
    data.map do |name, done|
      slug = name.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/_+$/, "")
      ListItem.new(slug, name, done)
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

Term2.run(FullLipglossModel.new, options: Term2::ProgramOptions.new(
  Term2::WithAltScreen.new,
  Term2::WithMouseAllMotion.new
))