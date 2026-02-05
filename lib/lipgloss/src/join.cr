require "./style"

module Lipgloss
  class Style
    # JoinHorizontal is a utility function for horizontally joining two
    # potentially multi-lined strings along a vertical axis.
    #
    # pos: Vertical alignment (Top, Bottom, Center)
    def self.join_horizontal(pos : Position, *strs : String) : String
      join_horizontal(pos, strs.to_a)
    end

    def self.join_horizontal(pos : Position, *strs : View) : String
      join_horizontal(pos, strs.map(&.content))
    end

    def self.join_horizontal(pos : Float64, *strs : String) : String
      join_horizontal(pos, strs.to_a)
    end

    def self.join_horizontal(pos : Float64, *strs : View) : String
      join_horizontal(pos, strs.map(&.content))
    end

    def self.join_horizontal(pos : Position, strs : Array(View)) : String
      join_horizontal(pos, strs.map(&.content))
    end

    def self.join_horizontal(pos : Position, strs : Array(String)) : String
      return "" if strs.empty?
      return strs[0] if strs.size == 1

      # Split strings into lines
      blocks = strs.map(&.split('\n'))

      # Calculate dimensions
      max_widths = blocks.map { |lines| lines.max_of { |l| Text.width(l) } rescue 0 }
      max_height = blocks.max_of(&.size) rescue 0

      # Normalize blocks to max_height by padding vertically
      blocks.each do |lines|
        if lines.size < max_height
          extra = max_height - lines.size

          case pos
          when Position::Top
            extra.times { lines << "" }
          when Position::Bottom
            extra.times { lines.unshift("") }
          when Position::Center
            top = extra // 2
            bottom = extra - top
            top.times { lines.unshift("") }
            bottom.times { lines << "" }
          else # Default to Top
            extra.times { lines << "" }
          end
        end
      end

      # Render joined blocks
      String.build do |io|
        max_height.times do |i|
          blocks.each_with_index do |lines, j|
            line = lines[i]
            io << line

            # Pad horizontal to block width so the next block aligns correctly
            if j < blocks.size - 1
              w = Text.width(line)
              pad = max_widths[j] - w
              io << " " * pad if pad > 0
            end
          end
          io << '\n' unless i == max_height - 1
        end
      end
    end

    def self.join_horizontal(pos : Float64, strs : Array(View)) : String
      join_horizontal(pos, strs.map(&.content))
    end

    def self.join_horizontal(pos : Float64, strs : Array(String)) : String
      return "" if strs.empty?
      return strs[0] if strs.size == 1

      blocks = strs.map(&.split('\n'))
      max_widths = blocks.map { |lines| lines.max_of { |l| Text.width(l) } rescue 0 }
      max_height = blocks.max_of(&.size) rescue 0
      ratio = pos.clamp(0.0, 1.0)

      blocks.each do |lines|
        if lines.size < max_height
          extra = max_height - lines.size
          top = (extra * ratio).round.to_i.clamp(0, extra)
          bottom = extra - top
          top.times { lines.unshift("") }
          bottom.times { lines << "" }
        end
      end

      String.build do |io|
        max_height.times do |i|
          blocks.each_with_index do |lines, j|
            line = lines[i]
            io << line
            if j < blocks.size - 1
              w = Text.width(line)
              pad = max_widths[j] - w
              io << " " * pad if pad > 0
            end
          end
          io << '\n' unless i == max_height - 1
        end
      end
    end

    # JoinVertical is a utility function for vertically joining two potentially
    # multi-lined strings along a horizontal axis.
    #
    # pos: Horizontal alignment (Left, Right, Center)
    def self.join_vertical(pos : Position, *strs : String) : String
      join_vertical(pos, strs.to_a)
    end

    def self.join_vertical(pos : Position, *strs : View) : String
      join_vertical(pos, strs.map(&.content))
    end

    def self.join_vertical(pos : Float64, *strs : String) : String
      join_vertical(pos, strs.to_a)
    end

    def self.join_vertical(pos : Float64, *strs : View) : String
      join_vertical(pos, strs.map(&.content))
    end

    def self.join_vertical(pos : Position, strs : Array(View)) : String
      join_vertical(pos, strs.map(&.content))
    end

    def self.join_vertical(pos : Position, strs : Array(String)) : String
      return "" if strs.empty?
      return strs[0] if strs.size == 1

      blocks = strs.map(&.split('\n'))

      # Calculate the widest line across all blocks
      max_width = blocks.max_of { |lines| lines.max_of { |l| Text.width(l) } rescue 0 } rescue 0

      String.build do |io|
        blocks.each_with_index do |lines, i|
          lines.each_with_index do |line, j|
            w = Text.width(line)
            gap = max_width - w

            if gap > 0
              case pos
              when Position::Left
                io << line
                io << " " * gap
              when Position::Right
                io << " " * gap
                io << line
              when Position::Center
                left = gap // 2
                right = gap - left
                io << " " * left
                io << line
                io << " " * right
              else # Default Left
                io << line
                io << " " * gap
              end
            else
              io << line
            end

            # Add newline unless it's the very last line of the very last block
            is_last_block = (i == blocks.size - 1)
            is_last_line = (j == lines.size - 1)

            unless is_last_block && is_last_line
              io << '\n'
            end
          end
        end
      end
    end

    def self.join_vertical(pos : Float64, strs : Array(View)) : String
      join_vertical(pos, strs.map(&.content))
    end

    def self.join_vertical(pos : Float64, strs : Array(String)) : String
      return "" if strs.empty?
      return strs[0] if strs.size == 1

      blocks = strs.map(&.split('\n'))
      max_width = blocks.max_of { |lines| lines.max_of { |l| Text.width(l) } rescue 0 } rescue 0
      ratio = pos.clamp(0.0, 1.0)

      String.build do |io|
        blocks.each_with_index do |lines, i|
          lines.each_with_index do |line, j|
            w = Text.width(line)
            gap = max_width - w
            left = (gap * ratio).round.to_i
            left = left.clamp(0, gap)
            right = gap - left

            io << " " * left
            io << line
            io << " " * right

            is_last_block = (i == blocks.size - 1)
            is_last_line = (j == lines.size - 1)
            io << '\n' unless is_last_block && is_last_line
          end
        end
      end
    end
  end
end
