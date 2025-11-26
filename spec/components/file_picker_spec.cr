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

  it "filters files" do
    fp = Term2::Components::FilePicker.new(temp_dir)
    fp.allowed_types = [".txt"]
    fp.read_dir # Re-read with filter

    fp.files.should contain "file1.txt"
    fp.files.should_not contain "file2.log"
    fp.files.should contain "subdir" # Dirs always shown
  end

  it "navigates directories" do
    fp = Term2::Components::FilePicker.new(temp_dir)

    # Find subdir index
    subdir_idx = fp.files.index!("subdir")

    # Move to subdir
    (subdir_idx).times do
      msg = Term2::KeyMsg.new(Term2::Key.new("down"))
      fp, _ = fp.update(msg)
    end

    # Enter
    msg = Term2::KeyMsg.new(Term2::Key.new("enter"))
    fp, _ = fp.update(msg)

    fp.current_directory.should end_with "subdir"
    fp.files.should contain "subfile.txt"

    # Back
    msg = Term2::KeyMsg.new(Term2::Key.new("backspace"))
    fp, _ = fp.update(msg)

    fp.current_directory.should end_with "filepicker_spec"
  end

  it "selects file" do
    fp = Term2::Components::FilePicker.new(temp_dir)

    # Find file1.txt
    idx = fp.files.index!("file1.txt")

    # Move to file
    idx.times do
      msg = Term2::KeyMsg.new(Term2::Key.new("down"))
      fp, _ = fp.update(msg)
    end

    # Select
    msg = Term2::KeyMsg.new(Term2::Key.new("enter"))
    fp, _ = fp.update(msg)

    selected = fp.selected_file
    selected.should_not be_nil
    if selected
      selected.should end_with "file1.txt"
    end
  end
end
