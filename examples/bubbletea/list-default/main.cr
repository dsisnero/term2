require "../../../src/term2"

include Term2::Prelude

struct Thing
  include TC::List::Item
  getter title : String
  getter description : String

  def initialize(@title : String, @description : String)
  end

  def filter_value : String
    @title
  end
end

class ListDefaultModel
  include Term2::Model

  DOC_STYLE = Term2::Style.new.margin(top: 1, right: 2, bottom: 1, left: 2)

  getter list : TC::List

  def initialize
    items = [
      Thing.new("Raspberry Pi’s", "I have ’em all over my house"),
      Thing.new("Nutella", "It's good on toast"),
      Thing.new("Bitter melon", "It cools you down"),
      Thing.new("Nice socks", "And by that I mean socks without holes"),
      Thing.new("Eight hours of sleep", "I had this once"),
      Thing.new("Cats", "Usually"),
      Thing.new("Plantasia, the album", "My plants love it too"),
      Thing.new("Pour over coffee", "It takes forever to make though"),
      Thing.new("VR", "Virtual reality...what is there to say?"),
      Thing.new("Noguchi Lamps", "Such pleasing organic forms"),
      Thing.new("Linux", "Pretty much the best OS"),
      Thing.new("Business school", "Just kidding"),
      Thing.new("Pottery", "Wet clay is a great feeling"),
      Thing.new("Shampoo", "Nothing like clean hair"),
      Thing.new("Table tennis", "It’s surprisingly exhausting"),
      Thing.new("Milk crates", "Great for packing in your extra stuff"),
      Thing.new("Afternoon tea", "Especially the tea sandwich part"),
      Thing.new("Stickers", "The thicker the vinyl the better"),
      Thing.new("20° Weather", "Celsius, not Fahrenheit"),
      Thing.new("Warm light", "Like around 2700 Kelvin"),
      Thing.new("The vernal equinox", "The autumnal equinox is pretty good too"),
      Thing.new("Gaffer’s tape", "Basically sticky fabric"),
      Thing.new("Terrycloth", "In other words, towel fabric"),
    ]

    @list = TC::List.new(items.map(&.as(TC::List::Item)), 0, 0)
    @list.show_title = true
    @list.show_filter = true
    @list.item_name_singular = "thing"
    @list.item_name_plural = "things"
    @list.paginator.per_page = 5
    @list.enumerator = TC::List::Enumerators::Bullet
    @list.delegate.as(TC::List::DefaultDelegate).selected_style = Term2::Style.new.foreground(Term2::Color::MAGENTA)
    @list.delegate.as(TC::List::DefaultDelegate).desc_style = Term2::Style.new.faint(true)
    @list.delegate.as(TC::List::DefaultDelegate).enumerator_style = Term2::Style.new
    @list_title = "My Fave Things"
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::WindowSizeMsg
      h = DOC_STYLE.get_horizontal_margins + DOC_STYLE.get_horizontal_padding
      v = DOC_STYLE.get_vertical_margins + DOC_STYLE.get_vertical_padding
      @list.width = msg.width - h
      @list.height = msg.height - v
    when Term2::KeyMsg
      if msg.key.to_s == "ctrl+c"
        return {self, Term2::Cmds.quit}
      end
    end

    @list, cmd = @list.update(msg)
    {self, cmd}
  end

  def view : String
    @list.title = @list_title
    DOC_STYLE.render(@list.view)
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(ListDefaultModel.new, options: Term2::ProgramOptions.new(Term2::WithAltScreen.new))
end
