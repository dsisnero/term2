module Ansi
  # ScreenPassthrough wraps the given ANSI sequence in a DCS passthrough
  # sequence to be sent to the outer terminal. This is used to send raw escape
  # sequences to the outer terminal when running inside GNU Screen.
  #
  #	DCS <data> ST
  #
  # Note: Screen limits the length of string sequences to 768 bytes (since 2014).
  # Use zero to indicate no limit, otherwise, this will chunk the returned
  # string into limit sized chunks.
  #
  # See: https://www.gnu.org/software/screen/manual/screen.html#String-Escapes
  # See: https://git.savannah.gnu.org/cgit/screen.git/tree/src/screen.h?id=c184c6ec27683ff1a860c45be5cf520d896fd2ef#n44
  def self.screen_passthrough(seq : String, limit : Int32) : String
    String.build do |io|
      io << "\eP"
      if limit > 0
        i = 0
        while i < seq.bytesize
          end_index = i + limit
          end_index = seq.bytesize if end_index > seq.bytesize
          io << seq.byte_slice(i, end_index - i)
          if end_index < seq.bytesize
            io << "\e\\\eP"
          end
          i = end_index
        end
      else
        io << seq
      end
      io << "\e\\"
    end
  end

  # TmuxPassthrough wraps the given ANSI sequence in a special DCS passthrough
  # sequence to be sent to the outer terminal. This is used to send raw escape
  # sequences to the outer terminal when running inside Tmux.
  #
  #	DCS tmux ; <escaped-data> ST
  #
  # Where <escaped-data> is the given sequence in which all occurrences of ESC
  # (0x1b) are doubled i.e. replaced with ESC ESC (0x1b 0x1b).
  #
  # Note: this needs the `allow-passthrough` option to be set to `on`.
  #
  # See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
  def self.tmux_passthrough(seq : String) : String
    String.build do |io|
      io << "\ePtmux;"
      seq.each_byte do |byte|
        if byte == C0::ESC
          io << byte.chr
        end
        io << byte.chr
      end
      io << "\e\\"
    end
  end
end
