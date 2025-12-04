require "../../../src/term2"

include Term2::Prelude

class PaginatorModel
  include Term2::Model

  getter items : Array(String)
  getter paginator : TC::Paginator

  def initialize
    @items = (1..100).map { |i| "Item #{i}" }.to_a
    @paginator = TC::Paginator.new
    @paginator.type = TC::Paginator::Type::Dots
    @paginator.per_page = 10
    @paginator.active_dot = Term2::Style.new.foreground(Term2::AdaptiveColor.new(light: Term2::Color.from_hex("235"), dark: Term2::Color.from_hex("252"))).render("•")
    @paginator.inactive_dot = Term2::Style.new.foreground(Term2::AdaptiveColor.new(light: Term2::Color.from_hex("250"), dark: Term2::Color.from_hex("238"))).render("•")
    @paginator.set_total_pages(@items.size)
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "esc", "ctrl+c"
        return {self, Term2::Cmds.quit}
      end
    end
    @paginator, cmd = @paginator.update(msg)
    {self, cmd}
  end

  def view : String
    String.build do |io|
      io << "\n  Paginator Example\n\n"
      start_idx, end_idx = @paginator.get_slice_bounds(@items.size)
      @items[start_idx...end_idx].each do |item|
        io << "  • #{item}\n\n"
      end
      io << "  " << @paginator.view
      io << "\n\n  h/l ←/→ page • q: quit\n"
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(PaginatorModel.new)
end
