module Ansi
  # C0 control characters.
  #
  # These range from (0x00-0x1F) as defined in ISO 646 (ASCII).
  # See: https://en.wikipedia.org/wiki/C0_and_C1_control_codes
  module C0
    # NUL is the null character (Caret: ^@, Char: \0).
    NUL = 0x00_u8
    # SOH is the start of heading character (Caret: ^A).
    SOH = 0x01_u8
    # STX is the start of text character (Caret: ^B).
    STX = 0x02_u8
    # ETX is the end of text character (Caret: ^C).
    ETX = 0x03_u8
    # EOT is the end of transmission character (Caret: ^D).
    EOT = 0x04_u8
    # ENQ is the enquiry character (Caret: ^E).
    ENQ = 0x05_u8
    # ACK is the acknowledge character (Caret: ^F).
    ACK = 0x06_u8
    # BEL is the bell character (Caret: ^G, Char: \a).
    BEL = 0x07_u8
    # BS is the backspace character (Caret: ^H, Char: \b).
    BS = 0x08_u8
    # HT is the horizontal tab character (Caret: ^I, Char: \t).
    HT = 0x09_u8
    # LF is the line feed character (Caret: ^J, Char: \n).
    LF = 0x0A_u8
    # VT is the vertical tab character (Caret: ^K, Char: \v).
    VT = 0x0B_u8
    # FF is the form feed character (Caret: ^L, Char: \f).
    FF = 0x0C_u8
    # CR is the carriage return character (Caret: ^M, Char: \r).
    CR = 0x0D_u8
    # SO is the shift out character (Caret: ^N).
    SO = 0x0E_u8
    # SI is the shift in character (Caret: ^O).
    SI = 0x0F_u8
    # DLE is the data link escape character (Caret: ^P).
    DLE = 0x10_u8
    # DC1 is the device control 1 character (Caret: ^Q).
    DC1 = 0x11_u8
    # DC2 is the device control 2 character (Caret: ^R).
    DC2 = 0x12_u8
    # DC3 is the device control 3 character (Caret: ^S).
    DC3 = 0x13_u8
    # DC4 is the device control 4 character (Caret: ^T).
    DC4 = 0x14_u8
    # NAK is the negative acknowledge character (Caret: ^U).
    NAK = 0x15_u8
    # SYN is the synchronous idle character (Caret: ^V).
    SYN = 0x16_u8
    # ETB is the end of transmission block character (Caret: ^W).
    ETB = 0x17_u8
    # CAN is the cancel character (Caret: ^X).
    CAN = 0x18_u8
    # EM is the end of medium character (Caret: ^Y).
    EM = 0x19_u8
    # SUB is the substitute character (Caret: ^Z).
    SUB = 0x1A_u8
    # ESC is the escape character (Caret: ^[, Char: \e).
    ESC = 0x1B_u8
    # FS is the file separator character (Caret: ^\).
    FS = 0x1C_u8
    # GS is the group separator character (Caret: ^]).
    GS = 0x1D_u8
    # RS is the record separator character (Caret: ^^).
    RS = 0x1E_u8
    # US is the unit separator character (Caret: ^_).
    US = 0x1F_u8

    # LS0 is the locking shift 0 character.
    # This is an alias for [SI].
    LS0 = SI
    # LS1 is the locking shift 1 character.
    # This is an alias for [SO].
    LS1 = SO
  end

  # Constants for easy access at module top level
  NUL = C0::NUL
  SOH = C0::SOH
  STX = C0::STX
  ETX = C0::ETX
  EOT = C0::EOT
  ENQ = C0::ENQ
  ACK = C0::ACK
  BEL = C0::BEL
  BS  = C0::BS
  HT  = C0::HT
  LF  = C0::LF
  VT  = C0::VT
  FF  = C0::FF
  CR  = C0::CR
  SO  = C0::SO
  SI  = C0::SI
  DLE = C0::DLE
  DC1 = C0::DC1
  DC2 = C0::DC2
  DC3 = C0::DC3
  DC4 = C0::DC4
  NAK = C0::NAK
  SYN = C0::SYN
  ETB = C0::ETB
  CAN = C0::CAN
  EM  = C0::EM
  SUB = C0::SUB
  ESC = C0::ESC
  FS  = C0::FS
  GS  = C0::GS
  RS  = C0::RS
  US  = C0::US
  LS0 = C0::LS0
  LS1 = C0::LS1
end
