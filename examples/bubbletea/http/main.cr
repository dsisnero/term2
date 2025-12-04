require "../../../src/term2"
require "http/client"

include Term2::Prelude

URL = "https://charm.sh/"

class StatusMsg < Term2::Message
  getter code : Int32

  def initialize(@code : Int32)
  end
end

class ErrMsg < Term2::Message
  getter error : Exception

  def initialize(@error : Exception)
  end

  def message : String
    @error.message || @error.to_s
  end
end

class HttpModel
  include Term2::Model

  getter status : Int32
  getter error : ErrMsg?

  def initialize
    @status = 0
    @error = nil
  end

  def init : Term2::Cmd
    -> { check_server }
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c", "esc"
        return {self, Term2::Cmds.quit}
      end
    when StatusMsg
      @status = msg.code
      return {self, Term2::Cmds.quit}
    when ErrMsg
      @error = msg
    end

    {self, nil}
  end

  def view : String
    s = "Checking #{URL}..."
    if err = @error
      s += "something went wrong: #{err.message}"
    elsif @status != 0
      text = HTTP::Status.from_value?(@status).try(&.description) || ""
      s += "#{@status} #{text}"
    end
    s + "\n"
  end

  private def check_server : Term2::Msg
    if override = ENV["TERM2_HTTP_EXAMPLE_STATUS"]?
      return StatusMsg.new(override.to_i)
    end

    client = HTTP::Client.new(URI.parse(URL))
    client.read_timeout = 10.seconds
    client.connect_timeout = 10.seconds
    begin
      res = client.get("/")
      StatusMsg.new(res.status_code.to_i)
    rescue ex
      ErrMsg.new(ex)
    ensure
      client.close
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(HttpModel.new)
end
