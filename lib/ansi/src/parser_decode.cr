module Ansi
  alias State = UInt8

  NormalState   = 0_u8
  PrefixState   = 1_u8
  ParamsState   = 2_u8
  IntermedState = 3_u8
  EscapeState   = 4_u8
  StringState   = 5_u8

  def self.decode_sequence(b : Bytes, state : UInt8, p : Parser? = nil)
    decode_sequence(Method::GraphemeWidth, b, state, p)
  end

  def self.decode_sequence(b : String, state : UInt8, p : Parser? = nil)
    _, width, n, new_state = decode_sequence(Method::GraphemeWidth, b.to_slice, state, p)
    {b.byte_slice(0, n), width, n, new_state}
  end

  def self.decode_sequence_wc(b : Bytes, state : UInt8, p : Parser? = nil)
    decode_sequence(Method::WcWidth, b, state, p)
  end

  def self.decode_sequence_wc(b : String, state : UInt8, p : Parser? = nil)
    _, width, n, new_state = decode_sequence(Method::WcWidth, b.to_slice, state, p)
    {b.byte_slice(0, n), width, n, new_state}
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def self.decode_sequence(m : Method, bytes : Bytes, state : State, p : Parser?)
    i = 0
    while i < bytes.size
      c = bytes[i]

      loop do
        case state
        when NormalState
          case c
          when ESC
            if p
              p.params[0] = ParserTransition::MissingParam if p.params.size > 0
              p.cmd = 0
              p.params_len = 0
              p.data_len = 0
            end
            state = EscapeState
            i += 1
            break
          when CSI, DCS
            if p
              p.params[0] = ParserTransition::MissingParam if p.params.size > 0
              p.cmd = 0
              p.params_len = 0
              p.data_len = 0
            end
            state = PrefixState
            i += 1
            break
          when OSC, APC, SOS, PM
            if p
              p.cmd = ParserTransition::MissingCommand
              p.data_len = 0
            end
            state = StringState
            i += 1
            break
          end

          if p
            p.data_len = 0
            p.params_len = 0
            p.cmd = 0
          end

          if c > US && c < DEL
            return {bytes[i, 1], 1, 1, NormalState}
          end

          if c <= US || c == DEL || c < 0xc0
            return {bytes[i, 1], 0, 1, NormalState}
          end

          if utf8_rune_start?(c)
            rw = utf8_byte_len(c)
            if rw == -1 || i + rw > bytes.size
              return {bytes[i, 1], 1, 1, NormalState}
            end
            valid = true
            j = 1
            while j < rw
              if (bytes[i + j] & 0xc0) != 0x80
                valid = false
                break
              end
              j += 1
            end
            unless valid
              return {bytes[i, 1], 1, 1, NormalState}
            end

            cluster_bytes, width = first_grapheme_cluster(bytes[i, bytes.size - i], m)
            if cluster_bytes.empty?
              return {bytes[i, 1], 1, 1, NormalState}
            end
            i += cluster_bytes.size
            return {bytes[0, i], width, i, NormalState}
          end

          return {bytes[0, i], 0, i, NormalState}
        when PrefixState
          if c >= '<'.ord && c <= '?'.ord
            if p
              p.cmd &= ~(0xff << ParserTransition::PrefixShift)
              p.cmd |= c.to_i << ParserTransition::PrefixShift
            end
            i += 1
            break
          end
          state = ParamsState
          next
        when ParamsState
          if c >= '0'.ord && c <= '9'.ord
            if p
              if p.params[p.params_len] == ParserTransition::MissingParam
                p.params[p.params_len] = 0
              end
              p.params[p.params_len] *= 10
              p.params[p.params_len] += (c - '0'.ord)
            end
            i += 1
            break
          end

          if c == ':'.ord
            p.params[p.params_len] |= ParserTransition::HasMoreFlag if p
          end

          if c == ';'.ord || c == ':'.ord
            if p
              p.params_len += 1
              p.params[p.params_len] = ParserTransition::MissingParam if p.params_len < p.params.size
            end
            i += 1
            break
          end

          state = IntermedState
          next
        when IntermedState
          if c >= ' '.ord && c <= '/'.ord
            if p
              p.cmd &= ~(0xff << ParserTransition::IntermedShift)
              p.cmd |= c.to_i << ParserTransition::IntermedShift
            end
            i += 1
            break
          end

          if p
            if (p.params_len > 0 && p.params_len < p.params.size - 1) ||
               (p.params_len == 0 && p.params.size > 0 && p.params[0] != ParserTransition::MissingParam)
              p.params_len += 1
            end
          end

          if c >= '@'.ord && c <= '~'.ord
            if p
              p.cmd &= ~0xff
              p.cmd |= c
            end

            if has_dcs_prefix?(bytes)
              p.data_len = 0 if p
              state = StringState
              i += 1
              break
            end

            return {bytes[0, i + 1], 0, i + 1, NormalState}
          end

          return {bytes[0, i], 0, i, NormalState}
        when EscapeState
          case c
          when '['.ord, 'P'.ord
            if p
              p.params[0] = ParserTransition::MissingParam if p.params.size > 0
              p.params_len = 0
              p.cmd = 0
            end
            state = PrefixState
            i += 1
            break
          when ']'.ord, 'X'.ord, '^'.ord, '_'.ord
            if p
              p.cmd = ParserTransition::MissingCommand
              p.data_len = 0
            end
            state = StringState
            i += 1
            break
          end

          if c >= ' '.ord && c <= '/'.ord
            if p
              p.cmd &= ~(0xff << ParserTransition::IntermedShift)
              p.cmd |= c.to_i << ParserTransition::IntermedShift
            end
            i += 1
            break
          elsif c >= '0'.ord && c <= '~'.ord
            if p
              p.cmd &= ~0xff
              p.cmd |= c
            end
            return {bytes[0, i + 1], 0, i + 1, NormalState}
          end

          return {bytes[0, i], 0, i, NormalState}
        when StringState
          case c
          when BEL
            if has_osc_prefix?(bytes)
              parse_osc_cmd(p)
              return {bytes[0, i + 1], 0, i + 1, NormalState}
            end
          when CAN, SUB
            parse_osc_cmd(p) if has_osc_prefix?(bytes)
            return {bytes[0, i], 0, i, NormalState}
          when ST
            parse_osc_cmd(p) if has_osc_prefix?(bytes)
            return {bytes[0, i + 1], 0, i + 1, NormalState}
          when ESC
            if has_st_prefix?(bytes[i, bytes.size - i])
              parse_osc_cmd(p) if has_osc_prefix?(bytes)
              return {bytes[0, i + 2], 0, i + 2, NormalState}
            end
            return {bytes[0, i], 0, i, NormalState}
          end

          if p && p.data_len < p.data.size
            p.data[p.data_len] = c
            p.data_len += 1

            if c == ';'.ord && has_osc_prefix?(bytes)
              parse_osc_cmd(p)
            end
          end

          i += 1
          break
        end
      end
    end

    {bytes, 0, bytes.size, state}
  end

  private def self.parse_osc_cmd(p : Parser?)
    return if p.nil? || p.cmd != ParserTransition::MissingCommand

    j = 0
    while j < p.data_len
      d = p.data[j]
      break if d < '0'.ord || d > '9'.ord
      p.cmd = 0 if p.cmd == ParserTransition::MissingCommand
      p.cmd *= 10
      p.cmd += d - '0'.ord
      j += 1
    end
  end

  def self.equal?(a : Bytes, b : Bytes) : Bool
    a == b
  end

  def self.equal?(a : String, b : String) : Bool
    a == b
  end

  def self.has_prefix?(b : Bytes, prefix : Bytes) : Bool
    b.size >= prefix.size && b[0, prefix.size] == prefix
  end

  def self.has_prefix?(b : String, prefix : String) : Bool
    b.starts_with?(prefix)
  end

  def self.has_suffix?(b : Bytes, suffix : Bytes) : Bool
    b.size >= suffix.size && b[b.size - suffix.size, suffix.size] == suffix
  end

  def self.has_suffix?(b : String, suffix : String) : Bool
    b.ends_with?(suffix)
  end

  def self.has_csi_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == CSI) || (b.size > 1 && b[0] == ESC && b[1] == '['.ord)
  end

  def self.has_csi_prefix?(b : String) : Bool
    has_csi_prefix?(b.to_slice)
  end

  def self.has_osc_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == OSC) || (b.size > 1 && b[0] == ESC && b[1] == ']'.ord)
  end

  def self.has_osc_prefix?(b : String) : Bool
    has_osc_prefix?(b.to_slice)
  end

  def self.has_apc_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == APC) || (b.size > 1 && b[0] == ESC && b[1] == '_'.ord)
  end

  def self.has_apc_prefix?(b : String) : Bool
    has_apc_prefix?(b.to_slice)
  end

  def self.has_dcs_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == DCS) || (b.size > 1 && b[0] == ESC && b[1] == 'P'.ord)
  end

  def self.has_dcs_prefix?(b : String) : Bool
    has_dcs_prefix?(b.to_slice)
  end

  def self.has_sos_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == SOS) || (b.size > 1 && b[0] == ESC && b[1] == 'X'.ord)
  end

  def self.has_sos_prefix?(b : String) : Bool
    has_sos_prefix?(b.to_slice)
  end

  def self.has_pm_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == PM) || (b.size > 1 && b[0] == ESC && b[1] == '^'.ord)
  end

  def self.has_pm_prefix?(b : String) : Bool
    has_pm_prefix?(b.to_slice)
  end

  def self.has_st_prefix?(b : Bytes) : Bool
    (b.size > 0 && b[0] == ST) || (b.size > 1 && b[0] == ESC && b[1] == '\\'.ord)
  end

  def self.has_st_prefix?(b : String) : Bool
    has_st_prefix?(b.to_slice)
  end

  def self.has_esc_prefix?(b : Bytes) : Bool
    b.size > 0 && b[0] == ESC
  end

  def self.has_esc_prefix?(b : String) : Bool
    has_esc_prefix?(b.to_slice)
  end

  def self.command(prefix : UInt8, inter : UInt8, final : UInt8) : Int32
    c = final.to_i
    c |= prefix.to_i << ParserTransition::PrefixShift
    c |= inter.to_i << ParserTransition::IntermedShift
    c
  end

  def self.parameter(p : Int32, has_more : Bool) : Int32
    value = p & ParserTransition::ParamMask
    value |= ParserTransition::HasMoreFlag if has_more
    value
  end

  private def self.utf8_rune_start?(b : UInt8) : Bool
    (b & 0xc0) != 0x80
  end

  private def self.utf8_byte_len(b : UInt8) : Int32
    if b <= 0x7f
      1
    elsif b >= 0xc0 && b <= 0xdf
      2
    elsif b >= 0xe0 && b <= 0xef
      3
    elsif b >= 0xf0 && b <= 0xf7
      4
    else
      -1
    end
  end
end
