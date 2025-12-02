# Helper module for lipgloss list examples
# Provides common list formatting functions

module LipglossListHelpers
  # Simple text formatter for lists
  def format_list(items : Array(String), indent : Int32 = 0, &block : Int32 -> String) : String
    String.build do |io|
      items.each_with_index do |item, i|
        prefix = block.call(i)
        io << " " * indent << prefix << item << "\n"
      end
    end
  end

  # Simple text formatter for lists without block
  def format_list(items : Array(String), indent : Int32 = 0) : String
    String.build do |io|
      items.each_with_index do |item, _|
        io << " " * indent << item << "\n"
      end
    end
  end

  # Roman numeral conversion (simple implementation for 1-10)
  def to_roman(num : Int32) : String
    case num
    when  1 then "I"
    when  2 then "II"
    when  3 then "III"
    when  4 then "IV"
    when  5 then "V"
    when  6 then "VI"
    when  7 then "VII"
    when  8 then "VIII"
    when  9 then "IX"
    when 10 then "X"
    else         num.to_s
    end
  end

  # Format a list with bullet points
  def bullet_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { "• " }
  end

  # Format a list with dashes
  def dash_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { "- " }
  end

  # Format a list with asterisks
  def asterisk_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { "* " }
  end

  # Format a list with lowercase alphabetical enumeration
  def lowercase_alphabet_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { |i| "#{('a'.ord + i).chr}. " }
  end

  # Format a list with uppercase alphabetical enumeration
  def uppercase_alphabet_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { |i| "#{('A'.ord + i).chr}. " }
  end

  # Format a list with Arabic numeral enumeration
  def arabic_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { |i| "#{i + 1}. " }
  end

  # Format a list with uppercase Roman numeral enumeration
  def uppercase_roman_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { |i| "#{to_roman(i + 1)}. " }
  end

  # Format a list with lowercase Roman numeral enumeration
  def lowercase_roman_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent) { |i| "#{to_roman(i + 1).downcase}. " }
  end

  # Format a list without enumeration
  def plain_list(items : Array(String), indent : Int32 = 0) : String
    format_list(items, indent)
  end
end