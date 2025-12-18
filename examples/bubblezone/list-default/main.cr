# Bubblezone list-default example.
# Original Go code: bubblezone/examples/list-default/main.go
require "../../../src/term2"

module BubblezoneListDefaultExample
  include Term2::Prelude

  alias Zone = Term2::Zone

  DOC_STYLE = Term2::Style.new.margin(top: 1, right: 2, bottom: 1, left: 2)

  struct Item
    include TC::List::Item

    getter id : String
    getter title : String
    getter description : String

    def initialize(@id : String, @title : String, @description : String)
    end

    def filter_value : String
      Zone.mark(@id, @title)
    end
  end

  class Delegate
    include TC::List::ItemDelegate

    @styles = TC::List::DefaultDelegate::DefaultItemStyles.new

    def height : Int32
      2
    end

    def spacing : Int32
      0
    end

    def update(msg : Msg, model : TC::List) : Cmd
      nil
    end

    def render(io : IO, model : TC::List, index : Int32, item : TC::List::Item)
      it = item.as(Item)
      if index == model.index
        io << @styles.selected_title.render(it.filter_value) << "\n"
        io << @styles.selected_desc.render(it.description)
      else
        io << @styles.normal_title.render(it.filter_value) << "\n"
        io << @styles.normal_desc.render(it.description)
      end
    end
  end

  class Model
    include Term2::Model

    getter list : TC::List

    def initialize
      items = [
        Item.new("item_1", "Raspberry Pi’s", "I have ’em all over my house"),
        Item.new("item_2", "Nutella", "It's good on toast"),
        Item.new("item_3", "Bitter melon", "It cools you down"),
        Item.new("item_4", "Nice socks", "And by that I mean socks without holes"),
        Item.new("item_5", "Eight hours of sleep", "I had this once"),
        Item.new("item_6", "Cats", "Usually"),
        Item.new("item_7", "Plantasia, the album", "My plants love it too"),
        Item.new("item_8", "Pour over coffee", "It takes forever to make though"),
        Item.new("item_9", "VR", "Virtual reality...what is there to say?"),
        Item.new("item_10", "Noguchi Lamps", "Such pleasing organic forms"),
        Item.new("item_11", "Linux", "Pretty much the best OS"),
        Item.new("item_12", "Business school", "Just kidding"),
        Item.new("item_13", "Pottery", "Wet clay is a great feeling"),
        Item.new("item_14", "Shampoo", "Nothing like clean hair"),
        Item.new("item_15", "Table tennis", "It’s surprisingly exhausting"),
        Item.new("item_16", "Milk crates", "Great for packing in your extra stuff"),
        Item.new("item_17", "Afternoon tea", "Especially the tea sandwich part"),
        Item.new("item_18", "Stickers", "The thicker the vinyl the better"),
        Item.new("item_19", "20° Weather", "Celsius, not Fahrenheit"),
        Item.new("item_20", "Warm light", "Like around 2700 Kelvin"),
        Item.new("item_21", "The vernal equinox", "The autumnal equinox is pretty good too"),
        Item.new("item_22", "Gaffer’s tape", "Basically sticky fabric"),
        Item.new("item_23", "Terrycloth", "In other words, towel fabric"),
      ]

      @list = TC::List.new(items.map(&.as(TC::List::Item)), 0, 0)
      @list.title = "Left click on an items title to select it"
      @list.delegate = Delegate.new
    end

    def init : Term2::Cmd
      nil
    end

    def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
      case msg
      when Term2::KeyMsg
        return {self, Term2::Cmds.quit} if msg.key.to_s == "ctrl+c"
      when Term2::WindowSizeMsg
        h = DOC_STYLE.get_horizontal_margins + DOC_STYLE.get_horizontal_padding
        v = DOC_STYLE.get_vertical_margins + DOC_STYLE.get_vertical_padding
        @list.width = msg.width - h
        @list.height = msg.height - v
      when Term2::MouseEvent
        case msg.button
        when Term2::MouseEvent::Button::WheelUp
          @list.cursor_up
          return {self, nil}
        when Term2::MouseEvent::Button::WheelDown
          @list.cursor_down
          return {self, nil}
        else
          # Handle zone clicks on mouse release.
          if msg.action == Term2::MouseEvent::Action::Release && msg.button == Term2::MouseEvent::Button::Left
            items = @list.visible_items
            start_idx, end_idx = @list.paginator.get_slice_bounds(items.size)
            page_items = items[start_idx...end_idx]

            page_items.each_with_index do |list_item, i|
              v = list_item.as(Item)
              if Zone.get(v.id).in_bounds?(msg)
                @list.select(i)
                break
              end
            end
          end
          return {self, nil}
        end
      end

      @list, cmd = @list.update(msg)
      {self, cmd}
    end

    def view : String
      DOC_STYLE.render(@list.view)
    end
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(BubblezoneListDefaultExample::Model.new, options: Term2::ProgramOptions.new(
    Term2::WithAltScreen.new,
    Term2::WithMouseCellMotion.new
  ))
end
