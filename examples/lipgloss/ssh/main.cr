require "../../../src/term2"
require "../styles"

include Term2::Prelude

class LibglossSshModel
  include Term2::Model

  def init : Term2::Cmd
    Term2::Cmds.none
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    {self, Term2::Cmds.none}
  end

  def view : String
    header = Lipgloss::Style.new
      .bold(true)
      .foreground(LibglossStyles::SPECIAL)
      .render("SSH Connection")

    body = <<-DOC
🍋 Host: citrus.example.com
🔐 User: @melon
🗝️  Key: ~/.ssh/citrus_ed25519
⌚ Last login: 2m ago

Terminal  information:
  Term: wezterm
  Width: 96, Height: 30

Command preview:
  $ cargo watch -x run
DOC

    LibglossStyles::DOC_STYLE.render([header, "", body].join("\n"))
  end
end

Term2.run(LibglossSshModel.new)
