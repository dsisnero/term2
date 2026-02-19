module Ansi
  # FinalTerm returns an escape sequence that is used for shell integrations.
  # Originally, FinalTerm designed the protocol hence the name.
  #
  #	OSC 133 ; Ps ; Pm ST
  #	OSC 133 ; Ps ; Pm BEL
  #
  # See: https://iterm2.com/documentation-shell-integration.html
  def self.final_term(*pm : String) : String
    "\e]133;#{pm.join(";")}\a"
  end

  # FinalTermPrompt returns an escape sequence that is used for shell
  # integrations prompt marks. This is sent just before the start of the shell
  # prompt.
  #
  # This is an alias for FinalTerm("A").
  def self.final_term_prompt(*pm : String) : String
    return final_term("A") if pm.empty?
    final_term(*(["A"] + pm))
  end

  # FinalTermCmdStart returns an escape sequence that is used for shell
  # integrations command start marks. This is sent just after the end of the
  # shell prompt, before the user enters a command.
  #
  # This is an alias for FinalTerm("B").
  def self.final_term_cmd_start(*pm : String) : String
    return final_term("B") if pm.empty?
    final_term(*(["B"] + pm))
  end

  # FinalTermCmdExecuted returns an escape sequence that is used for shell
  # integrations command executed marks. This is sent just before the start of
  # the command output.
  #
  # This is an alias for FinalTerm("C").
  def self.final_term_cmd_executed(*pm : String) : String
    return final_term("C") if pm.empty?
    final_term(*(["C"] + pm))
  end

  # FinalTermCmdFinished returns an escape sequence that is used for shell
  # integrations command finished marks.
  #
  # If the command was sent after
  # [FinalTermCmdStart], it indicates that the command was aborted. If the
  # command was sent after [FinalTermCmdExecuted], it indicates the end of the
  # command output. If neither was sent, [FinalTermCmdFinished] should be
  # ignored.
  #
  # This is an alias for FinalTerm("D").
  def self.final_term_cmd_finished(*pm : String) : String
    return final_term("D") if pm.empty?
    final_term(*(["D"] + pm))
  end
end
