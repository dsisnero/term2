require "./spec_helper"

module Term2
  describe Terminal do
    it "enters and exits alternate screen" do
      # These should not raise
      Terminal.enter_alt_screen
      Terminal.exit_alt_screen
    end

    it "shows and hides cursor" do
      # These should not raise
      io = IO::Memory.new
      Terminal.hide_cursor(io)
      Terminal.show_cursor(io)
    end

    it "enables and disables bracketed paste" do
      # These should not raise
      Terminal.enable_bracketed_paste
      Terminal.disable_bracketed_paste
    end

    it "enables and disables focus reporting" do
      # These should not raise
      Terminal.enable_focus_reporting
      Terminal.disable_focus_reporting
    end

    it "saves and restores terminal state" do
      # These should not raise
      Terminal.save_state
      Terminal.restore_state
    end

    it "releases and restores terminal" do
      # These should not raise
      Terminal.release_terminal
      Terminal.restore_terminal
    end

    it "clears the screen" do
      # This should not raise
      io = IO::Memory.new
      Terminal.clear(io)
    end

    it "checks if IO is a TTY" do
      Terminal.tty?.should be_a(Bool)
    end

    it "gets terminal size" do
      size = Terminal.size
      size.should be_a(Tuple(Int32, Int32))
      size[0].should be >= 0
      size[1].should be >= 0
    end
  end

  describe ProgramOptions do
    it "creates empty options" do
      options = ProgramOptions.new
      options.has_option?(WithAltScreen).should be_false
    end

    it "adds options" do
      options = ProgramOptions.new
      options.add(WithAltScreen.new)
      options.has_option?(WithAltScreen).should be_true
    end

    it "creates with initial options" do
      options = ProgramOptions.new(WithAltScreen.new, WithoutRenderer.new)
      options.has_option?(WithAltScreen).should be_true
      options.has_option?(WithoutRenderer).should be_true
    end

    it "gets options of specific type" do
      options = ProgramOptions.new(WithAltScreen.new, WithAltScreen.new, WithoutRenderer.new)
      alt_screen_options = options.get_options(WithAltScreen)
      alt_screen_options.size.should eq(2)
      renderer_options = options.get_options(WithoutRenderer)
      renderer_options.size.should eq(1)
    end
  end

  describe "terminal messages" do
    it "creates EnterAltScreenMsg" do
      msg = EnterAltScreenMsg.new
      msg.should be_a(Message)
    end

    it "creates ExitAltScreenMsg" do
      msg = ExitAltScreenMsg.new
      msg.should be_a(Message)
    end

    it "creates ShowCursorMsg" do
      msg = ShowCursorMsg.new
      msg.should be_a(Message)
    end

    it "creates HideCursorMsg" do
      msg = HideCursorMsg.new
      msg.should be_a(Message)
    end

    it "creates FocusMsg" do
      msg = FocusMsg.new
      msg.should be_a(Message)
    end

    it "creates BlurMsg" do
      msg = BlurMsg.new
      msg.should be_a(Message)
    end

    it "creates WindowSizeMsg with dimensions" do
      msg = WindowSizeMsg.new(80, 24)
      msg.should be_a(Message)
      msg.width.should eq(80)
      msg.height.should eq(24)
    end
  end

  describe "terminal commands" do
    it "creates enter_alt_screen command" do
      cmd = Cmds.enter_alt_screen
      cmd.should be_a(Cmd)
    end

    it "creates exit_alt_screen command" do
      cmd = Cmds.exit_alt_screen
      cmd.should be_a(Cmd)
    end

    it "creates show_cursor command" do
      cmd = Cmds.show_cursor
      cmd.should be_a(Cmd)
    end

    it "creates hide_cursor command" do
      cmd = Cmds.hide_cursor
      cmd.should be_a(Cmd)
    end

    it "creates println command" do
      cmd = Cmds.println("test")
      cmd.should be_a(Cmd)
    end

    it "creates printf command" do
      cmd = Cmds.printf("test %s", "value")
      cmd.should be_a(Cmd)
    end
  end
end
