require "../spec_helper"
require "../../src/components/file_picker"
require "file_utils"

describe Term2::Components::FilePicker do
  # Setup temp dir
  temp_dir = File.join("temp", "filepicker_spec")

  before_all do
    FileUtils.mkdir_p(temp_dir)
    FileUtils.mkdir_p(File.join(temp_dir, "subdir"))
    File.write(File.join(temp_dir, "file1.txt"), "content")
    File.write(File.join(temp_dir, "file2.log"), "content")
    File.write(File.join(temp_dir, "subdir", "subfile.txt"), "content")
  end

  after_all do
    FileUtils.rm_rf(temp_dir)
  end

  it "lists files" do
    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.files.should contain "file1.txt"
    fp.files.should contain "file2.log"
    fp.files.should contain "subdir"
  end

  it "disables selection for non-allowed types" do
    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.allowed_types = [".txt"]
    # Files should still include all entries
    fp.files.should contain "file2.log"
    # But can_select should return false for .log files
    fp.can_select("file1.txt").should be_true
    fp.can_select("file2.log").should be_false
    fp.can_select("subdir").should be_false # directories don't match .txt extension
  end

  it "navigates directories" do
    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.focus = true

    # Find subdir index
    subdir_idx = fp.files.index!("subdir")

    # Move to subdir
    subdir_idx.times do
      msg = Term2::KeyMsg.new(Term2::Key.new("down"))
      fp, _ = fp.update(msg)
    end

    # Open directory (enter or 'l' or 'right')
    msg = Term2::KeyMsg.new(Term2::Key.new("enter"))
    fp, _ = fp.update(msg)

    fp.current_directory.should end_with "subdir"
    fp.files.should contain "subfile.txt"

    # Back (h, backspace, left, esc)
    msg = Term2::KeyMsg.new(Term2::Key.new("h"))
    fp, _ = fp.update(msg)

    fp.current_directory.should end_with "filepicker_spec"
  end

  it "selects file" do
    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.focus = true

    # Find file1.txt
    idx = fp.files.index!("file1.txt")

    # Move to file
    idx.times do
      msg = Term2::KeyMsg.new(Term2::Key.new("down"))
      fp, _ = fp.update(msg)
    end

    # Select with enter (select key binding)
    msg = Term2::KeyMsg.new(Term2::Key.new("enter"))
    fp, _ = fp.update(msg)

    # Path should be set
    fp.path.should end_with "file1.txt"
  end

  it "handles key bindings correctly" do
    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.focus = true
    fp.set_height(5)
    file_count = fp.files.size

    # Test go to top (g)
    fp.selected = 3
    msg = Term2::KeyMsg.new(Term2::Key.new("g"))
    fp, _ = fp.update(msg)
    fp.selected.should eq 0

    # Test go to last (G)
    msg = Term2::KeyMsg.new(Term2::Key.new("G"))
    fp, _ = fp.update(msg)
    fp.selected.should eq(file_count - 1)

    # Test page down (J, pgdown, space) - should move by height, clamped to file count
    fp.selected = 0
    msg = Term2::KeyMsg.new(Term2::Key.new("J"))
    fp, _ = fp.update(msg)
    expected = Math.min(fp.height, file_count - 1)
    fp.selected.should eq(expected)

    # Test page up (K, pgup) - should move up by height, clamped to 0
    msg = Term2::KeyMsg.new(Term2::Key.new("K"))
    fp, _ = fp.update(msg)
    fp.selected.should eq(0)

    # Test down (j) and up (k)
    msg = Term2::KeyMsg.new(Term2::Key.new("j"))
    fp, _ = fp.update(msg)
    fp.selected.should eq(1)

    msg = Term2::KeyMsg.new(Term2::Key.new("k"))
    fp, _ = fp.update(msg)
    fp.selected.should eq(0)
  end

  it "shows/hides hidden files" do
    hidden_file = File.join(temp_dir, ".hidden")
    File.write(hidden_file, "secret")

    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.files.should_not contain ".hidden"

    fp.show_hidden = true
    fp.read_dir
    fp.files.should contain ".hidden"

    File.delete(hidden_file)
  end
end
