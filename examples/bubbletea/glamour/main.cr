require "../../../src/term2"
require "log"

include Term2::Prelude

Log.setup_from_env

CONTENT = <<-MD
# Today’s Menu

## Appetizers

| Name        | Price | Notes                           |
| ---         | ---   | ---                             |
| Tsukemono   | $2    | Just an appetizer               |
| Tomato Soup | $4    | Made with San Marzano tomatoes  |
| Okonomiyaki | $4    | Takes a few minutes to make     |
| Curry       | $3    | We can add squash if you’d like |

## Seasonal Dishes

| Name                 | Price | Notes              |
| ---                  | ---   | ---                |
| Steamed bitter melon | $2    | Not so bitter      |
| Takoyaki             | $3    | Fun to eat         |
| Winter squash        | $3    | Today it's pumpkin |

## Desserts

| Name         | Price | Notes                 |
| ---          | ---   | ---                   |
| Dorayaki     | $4    | Looks good on rabbits |
| Banana Split | $5    | A classic             |
| Cream Puff   | $3    | Pretty creamy!        |

All our dishes are made in-house by Karen, our chef. Most of our ingredients
are from our garden or the fish market down the street.

Some famous people that have eaten here lately:

* [x] René Redzepi
* [x] David Chang
* [ ] Jiro Ono (maybe some day)

Bon appétit!
MD

class GlamourModel
  include Term2::Model

  getter viewport : TC::Viewport

  def initialize
    width = 78
    vp = TC::Viewport.new(width, 20)
    vp.content = CONTENT
    @viewport = vp
  end

  def init : Term2::Cmd
    nil
  end

  def update(msg : Term2::Msg) : {Term2::Model, Term2::Cmd}
    case msg
    when Term2::KeyMsg
      case msg.key.to_s
      when "q", "ctrl+c", "esc"
        return {self, Term2::Cmds.quit}
      else
        @viewport, cmd = @viewport.update(msg)
        return {self, cmd}
      end
    end
    {self, nil}
  end

  def view : String
    "#{@viewport.view}\n\n  ↑/↓: Navigate • q: Quit\n"
  end
end

unless ENV["TERM2_REQUIRE_ONLY"]?
  Term2.run(GlamourModel.new)
end
