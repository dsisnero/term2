require "log"

module Term2
  # Configure Log from environment (LOG_LEVEL, LOG_OUTPUT)
  def self.setup_logging_from_env
    output = ENV["LOG_OUTPUT"]?
    backend =
      if output && !output.empty?
        file = File.open(output, "a")
        Log::IOBackend.new(file)
      else
        Log::IOBackend.new(STDERR)
      end

    # Delegate to Crystal's built-in env setup (respects LOG_LEVEL by default)
    Log.setup_from_env(default_level: Log::Severity::Info, backend: backend)
  end

  # Log to a file with prefix, returning the opened file.
  def self.log_to_file(path : String, prefix : String) : File
    file = File.open(path, "w")
    formatter = Log::Formatter.new do |entry, io|
      begin
        io << prefix << " " << entry.message
      rescue IO::Error
        # Ignore writes to closed streams to avoid crashing background log fiber
      end
    end
    backend = Log::IOBackend.new(file, formatter: formatter, dispatcher: Log::DispatchMode::Sync)
    Log.setup(:info, backend)
    file
  end
end
