module Ansi
  def self.urxvt_ext(extension : String, *params : String) : String
    "\e]777;#{extension};#{params.join(';')}\a"
  end

  def self.urxvt_ext(extension : String, params : Array(String)) : String
    "\e]777;#{extension};#{params.join(';')}\a"
  end
end
