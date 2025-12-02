require "log"

module Term2
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
