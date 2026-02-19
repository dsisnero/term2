require "./spec_helper"

describe "Ansi truncate" do
  truncate_cases = [
    {name: "empty", input: "", extra: "", width: 0, expect_right: "", expect_left: ""},
    {name: "truncate_length_0", input: "foo", extra: "", width: 0, expect_right: "", expect_left: "foo"},
    {name: "equalascii", input: "one", extra: ".", width: 3, expect_right: "one", expect_left: ""},
    {name: "equalemoji", input: "on👋", extra: ".", width: 3, expect_right: "on.", expect_left: ".👋"},
    {name: "simple multiple words", input: "a couple of words", extra: "", width: 6, expect_right: "a coup", expect_left: "le of words"},
    {name: "equalcontrolemoji", input: "one\x1b[0m", extra: ".", width: 3, expect_right: "one\x1b[0m", expect_left: "\x1b[0m"},
    {name: "truncate_tail_greater", input: "foo", extra: "...", width: 5, expect_right: "foo", expect_left: ""},
    {name: "simple", input: "foobar", extra: "", width: 3, expect_right: "foo", expect_left: "bar"},
    {name: "passthrough", input: "foobar", extra: "", width: 10, expect_right: "foobar", expect_left: ""},
    {name: "ascii", input: "hello", extra: "", width: 3, expect_right: "hel", expect_left: "lo"},
    {name: "emoji", input: "👋", extra: "", width: 2, expect_right: "👋", expect_left: ""},
    {name: "wideemoji", input: "🫧", extra: "", width: 2, expect_right: "🫧", expect_left: ""},
    {name: "controlemoji", input: "\x1b[31mhello 👋abc\x1b[0m", extra: "", width: 8, expect_right: "\x1b[31mhello 👋\x1b[0m", expect_left: "\x1b[31mabc\x1b[0m"},
    {
      name:         "osc8",
      input:        "\x1b]8;;https://charm.sh\x1b\\Charmbracelet 🫧\x1b]8;;\x1b\\",
      extra:        "",
      width:        5,
      expect_right: "\x1b]8;;https://charm.sh\x1b\\Charm\x1b]8;;\x1b\\",
      expect_left:  "\x1b]8;;https://charm.sh\x1b\\bracelet 🫧\x1b]8;;\x1b\\",
    },
    {
      name:         "osc8_8bit",
      input:        "\x9d8;;https://charm.sh\x9cCharmbracelet 🫧\x9d8;;\x9c",
      extra:        "",
      width:        5,
      expect_right: "\x9d8;;https://charm.sh\x9cCharm\x9d8;;\x9c",
      expect_left:  "\x9d8;;https://charm.sh\x9cbracelet 🫧\x9d8;;\x9c",
    },
    {name: "style_tail", input: "\x1B[38;5;219mHiya!", extra: "…", width: 3, expect_right: "\x1B[38;5;219mHi…", expect_left: "\x1B[38;5;219m…a!"},
    {name: "double_style_tail", input: "\x1B[38;5;219mHiya!\x1B[38;5;219mHello", extra: "…", width: 7, expect_right: "\x1B[38;5;219mHiya!\x1B[38;5;219mH…", expect_left: "\x1B[38;5;219m\x1B[38;5;219m…llo"},
    {name: "noop", input: "\x1B[7m--", extra: "", width: 2, expect_right: "\x1B[7m--", expect_left: "\x1b[7m"},
    {name: "double_width", input: "\x1B[38;2;249;38;114m你好\x1B[0m", extra: "", width: 3, expect_right: "\x1B[38;2;249;38;114m你\x1B[0m", expect_left: "\x1B[38;2;249;38;114m好\x1B[0m"},
    {name: "double_width_rune", input: "你", extra: "", width: 1, expect_right: "", expect_left: "你"},
    {name: "double_width_runes", input: "你好", extra: "", width: 2, expect_right: "你", expect_left: "好"},
    {name: "spaces_only", input: "    ", extra: "…", width: 2, expect_right: " …", expect_left: "…  "},
    {name: "longer_tail", input: "foo", extra: "...", width: 2, expect_right: "", expect_left: "...o"},
    {name: "same_tail_width", input: "foo", extra: "...", width: 3, expect_right: "foo", expect_left: ""},
    {name: "same_tail_width_control", input: "\x1b[31mfoo\x1b[0m", extra: "...", width: 3, expect_right: "\x1b[31mfoo\x1b[0m", expect_left: "\x1b[31m\x1b[0m"},
    {name: "same_width", input: "foo", extra: "", width: 3, expect_right: "foo", expect_left: ""},
    {name: "truncate_with_tail", input: "foobar", extra: ".", width: 4, expect_right: "foo.", expect_left: ".ar"},
    {name: "style", input: "I really \x1B[38;2;249;38;114mlove\x1B[0m Go!", extra: "", width: 8, expect_right: "I really\x1B[38;2;249;38;114m\x1B[0m", expect_left: " \x1B[38;2;249;38;114mlove\x1B[0m Go!"},
    {name: "dcs", input: "\x1BPq#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0#1~~@@vv@@~~@@~~$#2??}}GG}}??}}??-#1!14@\x1B\\foobar", extra: "…", width: 4, expect_right: "\x1BPq#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0#1~~@@vv@@~~@@~~$#2??}}GG}}??}}??-#1!14@\x1B\\foo…", expect_left: "\x1BPq#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0#1~~@@vv@@~~@@~~$#2??}}GG}}??}}??-#1!14@\x1B\\…ar"},
    {name: "emoji_tail", input: "\x1b[36mHello there!\x1b[m", extra: "😃", width: 8, expect_right: "\x1b[36mHello 😃\x1b[m", expect_left: "\x1b[36m😃ere!\x1b[m"},
    {name: "unicode", input: "\x1b[35mClaire‘s Boutique\x1b[0m", extra: "", width: 8, expect_right: "\x1b[35mClaire‘s\x1b[0m", expect_left: "\x1b[35m Boutique\x1b[0m"},
    {name: "wide_chars", input: "こんにちは", extra: "…", width: 7, expect_right: "こんに…", expect_left: "…ちは"},
    {name: "style_wide_chars", input: "\x1b[35mこんにちは\x1b[m", extra: "…", width: 7, expect_right: "\x1b[35mこんに…\x1b[m", expect_left: "\x1b[35m…ちは\x1b[m"},
    {name: "osc8_lf", input: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\\nสวัสดีสวัสดี\x1b]8;;\x1b\\", extra: "…", width: 9, expect_right: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\\n…\x1b]8;;\x1b\\", expect_left: "\x1b]8;;https://example.com\x1b\\…วัสดีสวัสดี\x1b]8;;\x1b\\"},
    {name: "simple japanese text prefix/suffix", input: "耐許ヱヨカハ調出あゆ監", extra: "…", width: 13, expect_right: "耐許ヱヨカハ…", expect_left: "…調出あゆ監"},
    {name: "simple japanese text", input: "耐許ヱヨカハ調出あゆ監", extra: "", width: 14, expect_right: "耐許ヱヨカハ調", expect_left: "出あゆ監"},
    {name: "new line inside and outside range", input: "\n\nsomething\nin\nthe\nway\n\n", extra: "-", width: 10, expect_right: "\n\nsomething\n-", expect_left: "-n\nthe\nway\n\n"},
    {
      name:         "multi-width graphemes with newlines - japanese text",
      input:        "耐許ヱヨカハ調出あゆ監件び理別よン國給災レホチ権輝モエフ会割もフ響3現エツ文時しだびほ経機ムイメフ敗文ヨク現義なさド請情ゆじょて憶主管州けでふく。排ゃわつげ美刊ヱミ出見ツ南者オ抜豆ハトロネ論索モネニイ任償スヲ話破リヤヨ秒止口イセソス止央のさ食周健でてつだ官送ト読聴遊容ひるべ。際ぐドらづ市居ネムヤ研校35岩6繹ごわク報拐イ革深52球ゃレスご究東スラ衝3間ラ録占たス。\n\n禁にンご忘康ざほぎル騰般ねど事超スんいう真表何カモ自浩ヲシミ図客線るふ静王ぱーま写村月掛焼詐面ぞゃ。昇強ごントほ価保キ族85岡モテ恋困ひりこな刊並せご出来ぼぎむう点目ヲウ止環公ニレ事応タス必書タメムノ当84無信升ちひょ。価ーぐ中客テサ告覧ヨトハ極整\nラ得95稿はかラせ江利ス宏丸霊ミ考整ス静将ず業巨職ノラホ収嗅ざな。",
      extra:        "",
      width:        14,
      expect_right: "耐許ヱヨカハ調",
      expect_left:  "出あゆ監件び理別よン國給災レホチ権輝モエフ会割もフ響3現エツ文時しだびほ経機ムイメフ敗文ヨク現義なさド請情ゆじょて憶主管州けでふく。排ゃわつげ美刊ヱミ出見ツ南者オ抜豆ハトロネ論索モネニイ任償スヲ話破リヤヨ秒止口イセソス止央のさ食周健でてつだ官送ト読聴遊容ひるべ。際ぐドらづ市居ネムヤ研校35岩6繹ごわク報拐イ革深52球ゃレスご究東スラ衝3間ラ録占たス。\n\n禁にンご忘康ざほぎル騰般ねど事超スんいう真表何カモ自浩ヲシミ図客線るふ静王ぱーま写村月掛焼詐面ぞゃ。昇強ごントほ価保キ族85岡モテ恋困ひりこな刊並せご出来ぼぎむう点目ヲウ止環公ニレ事応タス必書タメムノ当84無信升ちひょ。価ーぐ中客テサ告覧ヨトハ極整\nラ得95稿はかラせ江利ス宏丸霊ミ考整ス静将ず業巨職ノラホ収嗅ざな。",
    },
  ]

  it "truncates" do
    truncate_cases.each do |test_case|
      Ansi.truncate(test_case[:input], test_case[:width], test_case[:extra]).should eq test_case[:expect_right]
    end
  end

  it "truncates left" do
    truncate_cases.each do |test_case|
      Ansi.truncate_left(test_case[:input], test_case[:width], test_case[:extra]).should eq test_case[:expect_left]
    end
  end

  it "cuts" do
    cases = [
      {desc: "simple string", input: "This is a long string", left: 2, right: 6, expect: "is i"},
      {desc: "with ansi", input: "I really \x1B[38;2;249;38;114mlove\x1B[0m Go!", left: 4, right: 25, expect: "ally \x1b[38;2;249;38;114mlove\x1b[0m Go!"},
      {desc: "left is 0", input: "Foo \x1B[38;2;249;38;114mbar\x1B[0mbaz", left: 0, right: 5, expect: "Foo \x1B[38;2;249;38;114mb\x1B[0m"},
      {desc: "right is 0", input: "\x1b[7mHello\x1b[m", left: 3, right: 0, expect: ""},
      {desc: "right is less than left", input: "\x1b[7mHello\x1b[m", left: 3, right: 2, expect: ""},
      {desc: "cut size is 0", input: "\x1b[7mHello\x1b[m", left: 2, right: 2, expect: ""},
      {desc: "maintains open ansi", input: "\x1b[38;5;212;48;5;63mHello, Artichoke!\x1b[m", left: 7, right: 16, expect: "\x1b[38;5;212;48;5;63mArtichoke\x1b[m"},
      {desc: "multiline", input: "\n\x1b[38;2;98;98;98m\nif [ -f RE\nADME.md ]; then\x1b[m\n\x1b[38;2;98;98;98m    echo oi\x1b[m\n\x1b[38;2;98;98;98mfi\x1b[m\n", left: 8, right: 13, expect: "\x1b[38;2;98;98;98mRE\nADM\x1b[m\x1b[38;2;98;98;98m\x1b[m\x1b[38;2;98;98;98m\x1b[m"},
    ]

    cases.each do |test_case|
      Ansi.cut(test_case[:input], test_case[:left], test_case[:right]).should eq test_case[:expect]
    end
  end

  it "converts byte to grapheme range" do
    cases = [
      {name: "simple", input: "hello world from x/ansi", feed: {2, 9}, expect: {2, 9}},
      {name: "with emoji", input: " Downloads", feed: {4, 7}, expect: {2, 5}},
      {name: "start out of bounds", input: "some text", feed: {-1, 5}, expect: {0, 5}},
      {name: "end out of bounds", input: "some text", feed: {1, 50}, expect: {1, 9}},
    ]

    cases.each do |test_case|
      start, stop = Ansi.byte_to_grapheme_range(test_case[:input], test_case[:feed][0], test_case[:feed][1])
      start.should eq test_case[:expect][0]
      stop.should eq test_case[:expect][1]
    end
  end
end
