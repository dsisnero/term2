require "random"

module Packages
  PACKAGES = [
    "vegeutils",
    "libgardening",
    "currykit",
    "spicerack",
    "fullenglish",
    "eggy",
    "bad-kitty",
    "chai",
    "hojicha",
    "libtacos",
    "babys-monads",
    "libpurring",
    "currywurst-devel",
    "xmodmeow",
    "licorice-utils",
    "cashew-apple",
    "rock-lobster",
    "standmixer",
    "coffee-CUPS",
    "libesszet",
    "zeichenorientierte-benutzerschnittstellen",
    "schnurrkit",
    "old-socks-devel",
    "jalapeño",
    "molasses-utils",
    "xkohlrabi",
    "party-gherkin",
    "snow-peas",
    "libyuzu",
  ]

  def self.get_packages : Array(String)
    pkgs = PACKAGES.dup
    pkgs.shuffle!

    pkgs.map do |pkg|
      "#{pkg}-#{Random.rand(10)}.#{Random.rand(10)}.#{Random.rand(10)}"
    end
  end
end
