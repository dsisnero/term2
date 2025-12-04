require "../../../src/term2"

include Term2::Prelude

INSTALLED_STYLE = Term2::Style.new.margin(1, 2)
CHECK_MARK = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 42)).render("✓")
CURRENT_PKG_STYLE = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 211))

PACKAGES = [
  "himalayan-translucency@1.2.3",
  "compassion@2.4.6",
  "humility@3.5.7",
  "gentleness@4.6.8",
  "self-control@5.7.9",
  "plain-old-steel@0.9.2",
  "chit-chat@0.3.0",
  "instant@0.10.0",
]

class InstalledPkgMsg < Term2::Message
  getter pkg : String
  def initialize(@pkg : String); end
end

class PackageManagerModel
  include Term2::Model

  getter packages : Array(String)
  getter index : Int32
  getter width : Int32
  getter height : Int32
  getter spinner : TC::Spinner
  getter progress : TC::Progress
  getter? done : Bool

  def initialize
    @packages = PACKAGES.dup
    @index = 0
    @width = 0
    @height = 0
    @spinner = TC::Spinner.new
    @spinner.style = Term2::Style.new.foreground(Term2::Color.new(Term2::Color::Type::Indexed, 63))
    @progress = TC::Progress.new
    @progress.use_gradient = true
    @progress.width = 40
    @progress.show_percentage = false
    @done = false
  end

  def init : Term2::Cmd
    Term2::Cmds.batch(download_and_install(@packages[@index]), @spinner.tick)
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      @width = msg.width
      @height = msg.height
    when Term2::KeyMsg
      case msg.key.to_s
      when "ctrl+c", "esc", "q"
        return {self, Term2::Cmds.quit}
      end
    when InstalledPkgMsg
      pkg = @packages[@index]
      if @index >= @packages.size - 1
        @done = true
        return {self, Term2::Cmds.sequence(Term2::Cmds.printf("%s %s", CHECK_MARK, pkg), Term2::Cmds.quit)}
      end

      @index += 1
      progress_cmd = @progress.percent_cmd(@index.to_f / @packages.size)

      return {self, Term2::Cmds.batch(
        progress_cmd,
        Term2::Cmds.printf("%s %s", CHECK_MARK, pkg),
        download_and_install(@packages[@index]),
      )}
    when TC::Spinner::TickMsg
      @spinner, cmd = @spinner.update(msg)
      return {self, cmd}
    when TC::Progress::FrameMsg
      @progress, cmd = @progress.update(msg)
      return {self, cmd}
    end
    {self, nil}
  end

  def view : String
    n = @packages.size
    width_str = n.to_s
    w = width_str.size

    if @done
      return INSTALLED_STYLE.render("Done! Installed #{n} packages.\n")
    end

    pkg_count = " #{sprintf("%#{w}d", @index)}/#{sprintf("%#{w}d", n)}"

    spin = "#{@spinner.view} "
    prog = @progress.view
    cells_avail = Math.max(0, @width - Term2::Text.width(spin + prog + pkg_count))

    pkg_name = CURRENT_PKG_STYLE.render(@packages[@index])
    info = Term2::Style.new.max_width(cells_avail).render("Installing #{pkg_name}")

    cells_remaining = Math.max(0, @width - Term2::Text.width(spin + info + prog + pkg_count))
    gap = " " * cells_remaining

    "#{spin}#{info}#{gap}#{prog}#{pkg_count}"
  end

  private def download_and_install(pkg : String) : Term2::Cmd
    delay = Random.rand(0..500).milliseconds
    Term2::Cmds.tick(delay) { InstalledPkgMsg.new(pkg) }
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(PackageManagerModel.new)
end
