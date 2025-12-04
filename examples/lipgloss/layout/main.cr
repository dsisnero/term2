require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LayoutModel
  include Model

  getter tabs : Array(String)
  getter selected_tab : Int32

  def initialize
    @tabs = ["Overview", "Insights", "History", "Connections"]
    @selected_tab = 0
  end

  def init : Cmd
    Cmds.none
  end

  def update(msg : Message) : {Model, Cmd}
    case msg
    when KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c"
        {self, Term2.quit}
      when "tab", "right"
        @selected_tab = (@selected_tab + 1) % @tabs.size
        {self, Cmds.none}
      when "left"
        @selected_tab = (@selected_tab - 1 + @tabs.size) % @tabs.size
        {self, Cmds.none}
      else
        {self, Cmds.none}
      end
    else
      {self, Cmds.none}
    end
  end

  def view : String
    tab_blocks = @tabs.map_with_index do |label, idx|
      LibglossStyles.tab(label, idx == @selected_tab)
    end
    tab_row = tab_blocks.reduce("") do |acc, block|
      acc.empty? ? block : Term2.join_horizontal(Term2::Position::Top, acc, block)
    end

    stats = [
      "Sessions       742",
      "Errors         1",
      "Latency        72ms",
      "Uptime         99.98%",
    ]

    stats_block = stats.map { |line| LibglossStyles.panel(24, "Metrics", line) }.join("\n")

    timeline = Term2.join_vertical(Term2::Position::Left,
      LibglossStyles.panel(58, "Activity", "Live deployments streaming"),
      LibglossStyles.panel(58, "Notes", "Deploy early, ship with confidence.")
    )

    layout = [
      tab_row,
      "",
      Term2.join_horizontal(Term2::Position::Top, stats_block, timeline),
      "",
      LibglossStyles.panel(86, "Status", "All systems operational, no incidents reported."),
      "",
      "Press Tab/Arrow keys to rotate tabs, q to quit.",
    ].join("\n")

    LibglossStyles::DOC_STYLE.render(layout)
  end
end

Term2.run(LayoutModel.new)
