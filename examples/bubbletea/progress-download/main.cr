require "./tui"

include Term2::Prelude

# Simulate download progress; send 25% increments every second.
def start_download_simulation(program : Term2::Program(ProgressDownloadModel))
  spawn do
    total = 0.0
    while total < 1.0
      sleep 1.second
      total += 0.25
      program.send(ProgressMsg.new(total.clamp(0.0, 1.0)))
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  model = ProgressDownloadModel.new
  program = Term2::Program(ProgressDownloadModel).new(model)
  start_download_simulation(program)
  program.run
end
