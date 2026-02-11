module Charmtone
  VERSION = "0.1.0"

  enum Key
    Cumin
    Tang
    Yam
    Paprika
    Bengal
    Uni
    Sriracha
    Coral
    Salmon
    Chili
    Cherry
    Tuna
    Macaron
    Pony
    Cheeky
    Flamingo
    Dolly
    Blush
    Urchin
    Mochi
    Lilac
    Prince
    Violet
    Mauve
    Grape
    Plum
    Orchid
    Jelly
    Charple
    Hazy
    Ox
    Sapphire
    Guppy
    Oceania
    Thunder
    Anchovy
    Damson
    Malibu
    Sardine
    Zinc
    Turtle
    Lichen
    Guac
    Julep
    Bok
    Mustard
    Citron
    Zest
    Pepper
    BBQ
    Charcoal
    Iron
    Oyster
    Squid
    Smoke
    Ash
    Salt
    Butter
    Pickle
    Gator
    Spinach
    Pom
    Steak
    Toast
    NeueGuac
    NeueZinc

    @@names = nil.as(Hash(Key, String)?)
    @@colors = nil.as(Hash(Key, Tuple(UInt8, UInt8, UInt8, UInt8))?)

    def rgba : {UInt32, UInt32, UInt32, UInt32}
      r, g, b, a = self.class.colors[self]
      {r.to_u32 * 0x101_u32, g.to_u32 * 0x101_u32, b.to_u32 * 0x101_u32, a.to_u32 * 0x101_u32}
    end

    def hex : String
      r, g, b, _ = self.class.colors[self]
      "#%02X%02X%02X" % {r, g, b}
    end

    def is_primary? : Bool
      self.class.primary.includes?(self)
    end

    def is_secondary? : Bool
      self.class.secondary.includes?(self)
    end

    def is_tertiary? : Bool
      self.class.tertiary.includes?(self)
    end

    def to_s : String
      self.class.names[self]? || ""
    end

    def to_s(io : IO) : Nil
      io << to_s
    end

    def self.primary : Tuple(Key, Key, Key, Key, Key)
      {Charple, Dolly, Julep, Zest, Butter}
    end

    def self.secondary : Tuple(Key, Key, Key)
      {Hazy, Blush, Bok}
    end

    def self.tertiary : Tuple(Key, Key, Key, Key, Key, Key)
      {Turtle, Malibu, Violet, Tuna, Coral, Uni}
    end

    def self.names : Hash(Key, String)
      @@names ||= {
        Cumin    => "Cumin",
        Tang     => "Tang",
        Yam      => "Yam",
        Paprika  => "Paprika",
        Bengal   => "Bengal",
        Uni      => "Uni",
        Sriracha => "Sriracha",
        Coral    => "Coral",
        Salmon   => "Salmon",
        Chili    => "Chili",
        Cherry   => "Cherry",
        Tuna     => "Tuna",
        Macaron  => "Macaron",
        Pony     => "Pony",
        Cheeky   => "Cheeky",
        Flamingo => "Flamingo",
        Dolly    => "Dolly",
        Blush    => "Blush",
        Urchin   => "Urchin",
        Mochi    => "Crystal",
        Lilac    => "Lilac",
        Prince   => "Prince",
        Violet   => "Violet",
        Mauve    => "Mauve",
        Grape    => "Grape",
        Plum     => "Plum",
        Orchid   => "Orchid",
        Jelly    => "Jelly",
        Charple  => "Charple",
        Hazy     => "Hazy",
        Ox       => "Ox",
        Sapphire => "Sapphire",
        Guppy    => "Guppy",
        Oceania  => "Oceania",
        Thunder  => "Thunder",
        Anchovy  => "Anchovy",
        Damson   => "Damson",
        Malibu   => "Malibu",
        Sardine  => "Sardine",
        Zinc     => "Zinc",
        Turtle   => "Turtle",
        Lichen   => "Lichen",
        Guac     => "Guac",
        Julep    => "Julep",
        Bok      => "Bok",
        Mustard  => "Mustard",
        Citron   => "Citron",
        Zest     => "Zest",
        Pepper   => "Pepper",
        BBQ      => "BBQ",
        Charcoal => "Charcoal",
        Iron     => "Iron",
        Oyster   => "Oyster",
        Squid    => "Squid",
        Smoke    => "Smoke",
        Ash      => "Ash",
        Salt     => "Salt",
        Butter   => "Butter",
        Pickle   => "Pickle",
        Gator    => "Gator",
        Spinach  => "Spinach",
        Pom      => "Pom",
        Steak    => "Steak",
        Toast    => "Toast",
        NeueGuac => "Neue Guac",
        NeueZinc => "Neue Zinc",
      }
    end

    def self.colors : Hash(Key, Tuple(UInt8, UInt8, UInt8, UInt8))
      @@colors ||= {
        Cumin    => {0xBF_u8, 0x97_u8, 0x6F_u8, 0xFF_u8},
        Tang     => {0xFF_u8, 0x98_u8, 0x5A_u8, 0xFF_u8},
        Yam      => {0xFF_u8, 0xB5_u8, 0x87_u8, 0xFF_u8},
        Paprika  => {0xD3_u8, 0x6C_u8, 0x64_u8, 0xFF_u8},
        Bengal   => {0xFF_u8, 0x6E_u8, 0x63_u8, 0xFF_u8},
        Uni      => {0xFF_u8, 0x93_u8, 0x7D_u8, 0xFF_u8},
        Sriracha => {0xEB_u8, 0x42_u8, 0x68_u8, 0xFF_u8},
        Coral    => {0xFF_u8, 0x57_u8, 0x7D_u8, 0xFF_u8},
        Salmon   => {0xFF_u8, 0x7F_u8, 0x90_u8, 0xFF_u8},
        Chili    => {0xE2_u8, 0x30_u8, 0x80_u8, 0xFF_u8},
        Cherry   => {0xFF_u8, 0x38_u8, 0x8B_u8, 0xFF_u8},
        Tuna     => {0xFF_u8, 0x6D_u8, 0xAA_u8, 0xFF_u8},
        Macaron  => {0xE9_u8, 0x40_u8, 0xB0_u8, 0xFF_u8},
        Pony     => {0xFF_u8, 0x4F_u8, 0xBF_u8, 0xFF_u8},
        Cheeky   => {0xFF_u8, 0x79_u8, 0xD0_u8, 0xFF_u8},
        Flamingo => {0xF9_u8, 0x47_u8, 0xE3_u8, 0xFF_u8},
        Dolly    => {0xFF_u8, 0x60_u8, 0xFF_u8, 0xFF_u8},
        Blush    => {0xFF_u8, 0x84_u8, 0xFF_u8, 0xFF_u8},
        Urchin   => {0xC3_u8, 0x37_u8, 0xE0_u8, 0xFF_u8},
        Mochi    => {0xEB_u8, 0x5D_u8, 0xFF_u8, 0xFF_u8},
        Lilac    => {0xF3_u8, 0x79_u8, 0xFF_u8, 0xFF_u8},
        Prince   => {0x9C_u8, 0x35_u8, 0xE1_u8, 0xFF_u8},
        Violet   => {0xC2_u8, 0x59_u8, 0xFF_u8, 0xFF_u8},
        Mauve    => {0xD4_u8, 0x6E_u8, 0xFF_u8, 0xFF_u8},
        Grape    => {0x71_u8, 0x34_u8, 0xDD_u8, 0xFF_u8},
        Plum     => {0x99_u8, 0x53_u8, 0xFF_u8, 0xFF_u8},
        Orchid   => {0xAD_u8, 0x6E_u8, 0xFF_u8, 0xFF_u8},
        Jelly    => {0x4A_u8, 0x30_u8, 0xD9_u8, 0xFF_u8},
        Charple  => {0x6B_u8, 0x50_u8, 0xFF_u8, 0xFF_u8},
        Hazy     => {0x8B_u8, 0x75_u8, 0xFF_u8, 0xFF_u8},
        Ox       => {0x33_u8, 0x31_u8, 0xB2_u8, 0xFF_u8},
        Sapphire => {0x49_u8, 0x49_u8, 0xFF_u8, 0xFF_u8},
        Guppy    => {0x72_u8, 0x72_u8, 0xFF_u8, 0xFF_u8},
        Oceania  => {0x2B_u8, 0x55_u8, 0xB3_u8, 0xFF_u8},
        Thunder  => {0x47_u8, 0x76_u8, 0xFF_u8, 0xFF_u8},
        Anchovy  => {0x71_u8, 0x9A_u8, 0xFC_u8, 0xFF_u8},
        Damson   => {0x00_u8, 0x7A_u8, 0xB8_u8, 0xFF_u8},
        Malibu   => {0x00_u8, 0xA4_u8, 0xFF_u8, 0xFF_u8},
        Sardine  => {0x4F_u8, 0xBE_u8, 0xFE_u8, 0xFF_u8},
        Zinc     => {0x10_u8, 0xB1_u8, 0xAE_u8, 0xFF_u8},
        Turtle   => {0x0A_u8, 0xDC_u8, 0xD9_u8, 0xFF_u8},
        Lichen   => {0x5C_u8, 0xDF_u8, 0xEA_u8, 0xFF_u8},
        Guac     => {0x12_u8, 0xC7_u8, 0x8F_u8, 0xFF_u8},
        Julep    => {0x00_u8, 0xFF_u8, 0xB2_u8, 0xFF_u8},
        Bok      => {0x68_u8, 0xFF_u8, 0xD6_u8, 0xFF_u8},
        Mustard  => {0xF5_u8, 0xEF_u8, 0x34_u8, 0xFF_u8},
        Citron   => {0xE8_u8, 0xFF_u8, 0x27_u8, 0xFF_u8},
        Zest     => {0xE8_u8, 0xFE_u8, 0x96_u8, 0xFF_u8},
        Pepper   => {0x20_u8, 0x1F_u8, 0x26_u8, 0xFF_u8},
        BBQ      => {0x2D_u8, 0x2C_u8, 0x35_u8, 0xFF_u8},
        Charcoal => {0x3A_u8, 0x39_u8, 0x43_u8, 0xFF_u8},
        Iron     => {0x4D_u8, 0x4C_u8, 0x57_u8, 0xFF_u8},
        Oyster   => {0x60_u8, 0x5F_u8, 0x6B_u8, 0xFF_u8},
        Squid    => {0x85_u8, 0x83_u8, 0x92_u8, 0xFF_u8},
        Smoke    => {0xBF_u8, 0xBC_u8, 0xC8_u8, 0xFF_u8},
        Ash      => {0xDF_u8, 0xDB_u8, 0xDD_u8, 0xFF_u8},
        Salt     => {0xF1_u8, 0xEF_u8, 0xEF_u8, 0xFF_u8},
        Butter   => {0xFF_u8, 0xFA_u8, 0xF1_u8, 0xFF_u8},
        Pickle   => {0x00_u8, 0xA4_u8, 0x75_u8, 0xFF_u8},
        Gator    => {0x18_u8, 0x46_u8, 0x3D_u8, 0xFF_u8},
        Spinach  => {0x1C_u8, 0x36_u8, 0x34_u8, 0xFF_u8},
        Pom      => {0xAB_u8, 0x24_u8, 0x54_u8, 0xFF_u8},
        Steak    => {0x58_u8, 0x22_u8, 0x38_u8, 0xFF_u8},
        Toast    => {0x41_u8, 0x21_u8, 0x30_u8, 0xFF_u8},
        NeueGuac => {0x00_u8, 0xB8_u8, 0x75_u8, 0xFF_u8},
        NeueZinc => {0x0E_u8, 0x99_u8, 0x96_u8, 0xFF_u8},
      }
    end
  end

  def self.keys : Array(Key)
    [
      Key::Cumin,
      Key::Tang,
      Key::Yam,
      Key::Paprika,
      Key::Bengal,
      Key::Uni,
      Key::Sriracha,
      Key::Coral,
      Key::Salmon,
      Key::Chili,
      Key::Cherry,
      Key::Tuna,
      Key::Macaron,
      Key::Pony,
      Key::Cheeky,
      Key::Flamingo,
      Key::Dolly,
      Key::Blush,
      Key::Urchin,
      Key::Mochi,
      Key::Lilac,
      Key::Prince,
      Key::Violet,
      Key::Mauve,
      Key::Grape,
      Key::Plum,
      Key::Orchid,
      Key::Jelly,
      Key::Charple,
      Key::Hazy,
      Key::Ox,
      Key::Sapphire,
      Key::Guppy,
      Key::Oceania,
      Key::Thunder,
      Key::Anchovy,
      Key::Damson,
      Key::Malibu,
      Key::Sardine,
      Key::Zinc,
      Key::Turtle,
      Key::Lichen,
      Key::Guac,
      Key::Julep,
      Key::Bok,
      Key::Mustard,
      Key::Citron,
      Key::Zest,
      Key::Pepper,
      Key::BBQ,
      Key::Charcoal,
      Key::Iron,
      Key::Oyster,
      Key::Squid,
      Key::Smoke,
      Key::Ash,
      Key::Salt,
      Key::Butter,
    ]
  end
end
