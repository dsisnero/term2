module Ansi
  # C1 control characters.
  #
  # These range from (0x80-0x9F) as defined in ISO 6429 (ECMA-48).
  # See: https://en.wikipedia.org/wiki/C0_and_C1_control_codes
  module C1
    # PAD is the padding character.
    PAD = 0x80_u8
    # HOP is the high octet preset character.
    HOP = 0x81_u8
    # BPH is the break permitted here character.
    BPH = 0x82_u8
    # NBH is the no break here character.
    NBH = 0x83_u8
    # IND is the index character.
    IND = 0x84_u8
    # NEL is the next line character.
    NEL = 0x85_u8
    # SSA is the start of selected area character.
    SSA = 0x86_u8
    # ESA is the end of selected area character.
    ESA = 0x87_u8
    # HTS is the horizontal tab set character.
    HTS = 0x88_u8
    # HTJ is the horizontal tab with justification character.
    HTJ = 0x89_u8
    # VTS is the vertical tab set character.
    VTS = 0x8A_u8
    # PLD is the partial line forward character.
    PLD = 0x8B_u8
    # PLU is the partial line backward character.
    PLU = 0x8C_u8
    # RI is the reverse index character.
    RI = 0x8D_u8
    # SS2 is the single shift 2 character.
    SS2 = 0x8E_u8
    # SS3 is the single shift 3 character.
    SS3 = 0x8F_u8
    # DCS is the device control string character.
    DCS = 0x90_u8
    # PU1 is the private use 1 character.
    PU1 = 0x91_u8
    # PU2 is the private use 2 character.
    PU2 = 0x92_u8
    # STS is the set transmit state character.
    STS = 0x93_u8
    # CCH is the cancel character.
    CCH = 0x94_u8
    # MW is the message waiting character.
    MW = 0x95_u8
    # SPA is the start of guarded area character.
    SPA = 0x96_u8
    # EPA is the end of guarded area character.
    EPA = 0x97_u8
    # SOS is the start of string character.
    SOS = 0x98_u8
    # SGCI is the single graphic character introducer character.
    SGCI = 0x99_u8
    # SCI is the single character introducer character.
    SCI = 0x9A_u8
    # CSI is the control sequence introducer character.
    CSI = 0x9B_u8
    # ST is the string terminator character.
    ST = 0x9C_u8
    # OSC is the operating system command character.
    OSC = 0x9D_u8
    # PM is the privacy message character.
    PM = 0x9E_u8
    # APC is the application program command character.
    APC = 0x9F_u8
  end

  # Constants for easy access at module top level
  PAD  = C1::PAD
  HOP  = C1::HOP
  BPH  = C1::BPH
  NBH  = C1::NBH
  IND  = C1::IND
  NEL  = C1::NEL
  SSA  = C1::SSA
  ESA  = C1::ESA
  HTS  = C1::HTS
  HTJ  = C1::HTJ
  VTS  = C1::VTS
  PLD  = C1::PLD
  PLU  = C1::PLU
  RI   = C1::RI
  SS2  = C1::SS2
  SS3  = C1::SS3
  DCS  = C1::DCS
  PU1  = C1::PU1
  PU2  = C1::PU2
  STS  = C1::STS
  CCH  = C1::CCH
  MW   = C1::MW
  SPA  = C1::SPA
  EPA  = C1::EPA
  SOS  = C1::SOS
  SGCI = C1::SGCI
  SCI  = C1::SCI
  CSI  = C1::CSI
  ST   = C1::ST
  OSC  = C1::OSC
  PM   = C1::PM
  APC  = C1::APC
end
