require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LayoutModel
  include Term2::Model

  getter tabs : Array(String)
  getter selected_tab : Int32

  def initialize
    @tabs = ["Overview", "Insights", "History", "Connections"]
    @selected_tab = 0
  end

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.string
      when "q", "ctrl+c"
        {self, Term2::Cmds.quit}
      when "tab", "right"
        @selected_tab = (@selected_tab + 1) % @tabs.size
        {self, Term2::Cmds.none}
      when "left"
        @selected_tab = (@selected_tab - 1 + @tabs.size) % @tabs.size
        {self, Term2::Cmds.none}
      else
        {self, Term2::Cmds.none}
      end
    else
      {self, Term2::Cmds.none}
    end
  end

  def view : String
    tab_blocks = @tabs.map_with_index do |label, idx|
      LibglossStyles.tab(label, idx == @selected_tab)
    end
    tab_row = tab_blocks.reduce("") do |acc, block|
      acc.empty? ? block : Lipgloss.join_horizontal(Lipgloss::Position::Top, acc, block)
    end

    stats = [
      "Sessions       742",
      "Errors         1",
      "Latency        72ms",
      "Uptime         99.98%",
    ]

    stats_block = stats.map { |line| LibglossStyles.panel(24, "Metrics", line) }.join("\n")

    timeline = Lipgloss.join_vertical(Lipgloss::Position::Left,
      LibglossStyles.panel(58, "Activity", "Live deployments streaming"),
      LibglossStyles.panel(58, "Notes", "Deploy early, ship with confidence.")
    )

    layout = [
      tab_row,
      "",
      Lipgloss.join_horizontal(Lipgloss::Position::Top, stats_block, timeline),
      "",
      LibglossStyles.panel(86, "Status", "All systems operational, no incidents reported."),
      "",
      "Press Tab/Arrow keys to rotate tabs, q to quit.",
    ].join("\n")

    LibglossStyles::DOC_STYLE.render(layout)
  end
end

Term2.run(LayoutModel.new)
