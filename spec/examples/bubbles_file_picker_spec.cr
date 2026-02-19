require "file_utils"
ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "teatest"
require "../../examples/bubbles_file_picker"

private def with_temp_dir(&)
  dir = File.join(Dir.tempdir, "term2-file-picker-#{Random::Secure.hex(4)}")
  Dir.mkdir(dir)
  begin
    yield dir
  ensure
    FileUtils.rm_r(dir)
  end
end

describe "Example: bubbles_file_picker" do
  it "renders files from the configured directory" do
    with_temp_dir do |dir|
      alpha = File.join(dir, "alpha.cr")
      beta = File.join(dir, "beta.md")
      ignored = File.join(dir, "ignored.txt")
      File.write(alpha, "")
      File.write(beta, "")
      File.write(ignored, "")

      File.chmod(alpha, 0o644)
      File.chmod(beta, 0o644)
      File.chmod(ignored, 0o644)

      prev_renderer = Lipgloss::StyleRenderer.default
      ansi_renderer = Lipgloss::StyleRenderer.new
      ansi_renderer.color_profile = Lipgloss::ColorProfile::ANSI256
      Lipgloss::StyleRenderer.default = ansi_renderer

      begin
        model = FilePickerModel.new
        model.picker = Term2::Components::FilePicker.new(path: dir)
        model.picker.allowed_types = [".cr", ".md", ".yml", ".json"]
        model.picker.show_hidden = false
        model.picker.focus = true

        model, _ = model.update(Term2::UV::WindowSizeEvent.new(80, 24))
        # Some runs can carry a transient empty selection state through update;
        # normalize to the pre-selection rendering state for deterministic golden output.
        model.selected_file = nil

        golden_dir = Golden.spec_test_data_dir || "spec/testdata"
        golden_path = File.join(golden_dir, "BubblesFilePicker", "default.golden")
        unless File.exists?(golden_path)
          raise "Missing golden file #{golden_path}. Run scripts/golden/gen_file_picker_golden.sh to generate it."
        end

        view = model.view
        output = view.is_a?(String) ? view : view.content
        output = output.gsub("\e[0m", "\e[m")
        Teatest.require_equal_output("BubblesFilePicker/default", output.to_slice)
      ensure
        Lipgloss::StyleRenderer.default = prev_renderer
      end
    end
  end
end
