require "./spec_helper"

describe "Ansi wrapping" do
  hardwrap_cases = [
    {name: "empty string", input: "", limit: 0, expected: "", preserve_space: true},
    {name: "passthrough", input: "foobar\n ", limit: 0, expected: "foobar\n ", preserve_space: true},
    {name: "pass", input: "foo", limit: 4, expected: "foo", preserve_space: true},
    {name: "simple", input: "foobarfoo", limit: 4, expected: "foob\narfo\no", preserve_space: true},
    {name: "lf", input: "f\no\nobar", limit: 3, expected: "f\no\noba\nr", preserve_space: true},
    {name: "lf_space", input: "foo bar\n  baz", limit: 3, expected: "foo\n ba\nr\n  b\naz", preserve_space: true},
    {name: "tab", input: "foo\tbar", limit: 3, expected: "foo\n\tbar", preserve_space: true},
    {name: "unicode_space", input: "foo\u00a0bar", limit: 3, expected: "foo\nbar", preserve_space: false},
    {
      name:           "style_nochange",
      input:          "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
      limit:          7,
      expected:       "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m",
      preserve_space: true,
    },
    {
      name:           "style",
      input:          "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m",
      limit:          3,
      expected:       "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mju\nst \nano\nthe\nr t\nest\x1B[38;2;249;38;114m\n)\x1B[0m",
      preserve_space: true,
    },
    {name: "style_lf", input: "I really \x1B[38;2;249;38;114mlove\x1B[0m Go!", limit: 8, expected: "I really\n\x1b[38;2;249;38;114mlove\x1b[0m Go!", preserve_space: false},
    {name: "style_emoji", input: "I really \x1B[38;2;249;38;114mlove u🫧\x1B[0m", limit: 8, expected: "I really\n\x1b[38;2;249;38;114mlove u🫧\x1b[0m", preserve_space: false},
    {name: "hyperlink", input: "I really \x1B]8;;https://example.com/\x1B\\love\x1B]8;;\x1B\\ Go!", limit: 10, expected: "I really \x1b]8;;https://example.com/\x1b\\l\nove\x1b]8;;\x1b\\ Go!", preserve_space: false},
    {name: "dcs", input: "\x1BPq#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0#1~~@@vv@@~~@@~~$#2??}}GG}}??}}??-#1!14@\x1B\\foobar", limit: 3, expected: "\x1BPq#0;2;0;0;0#1;2;100;100;0#2;2;0;100;0#1~~@@vv@@~~@@~~$#2??}}GG}}??}}??-#1!14@\x1B\\foo\nbar", preserve_space: false},
    {name: "begin_with_space", input: " foo", limit: 4, expected: " foo", preserve_space: false},
    {name: "style_dont_affect_wrap", input: "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", limit: 7, expected: "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", preserve_space: false},
    {name: "preserve_style", input: "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m", limit: 3, expected: "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mju\nst \nano\nthe\nr t\nest\x1B[38;2;249;38;114m\n)\x1B[0m", preserve_space: false},
    {name: "emoji", input: "foo🫧foobar", limit: 4, expected: "foo\n🫧fo\nobar", preserve_space: false},
    {name: "osc8_wrap", input: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\สวัสดีสวัสดี\x1b]8;;\x1b\\", limit: 8, expected: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\\nสวัสดีสวัสดี\x1b]8;;\x1b\\", preserve_space: false},
    {name: "column", input: "VERTICAL", limit: 1, expected: "V\nE\nR\nT\nI\nC\nA\nL", preserve_space: false},
  ]

  it "hardwraps" do
    hardwrap_cases.each do |test_case|
      Ansi.hardwrap(test_case[:input], test_case[:limit], test_case[:preserve_space]).should eq test_case[:expected]
    end
  end

  wordwrap_cases = [
    {name: "empty string", input: "", limit: 0, breakpoints: "", expected: ""},
    {name: "passthrough", input: "foobar\n ", limit: 0, breakpoints: "", expected: "foobar\n "},
    {name: "pass", input: "foo", limit: 3, breakpoints: "", expected: "foo"},
    {name: "toolong", input: "foobarfoo", limit: 4, breakpoints: "", expected: "foobarfoo"},
    {name: "white space", input: "foo bar foo", limit: 4, breakpoints: "", expected: "foo\nbar\nfoo"},
    {name: "broken_at_spaces", input: "foo bars foobars", limit: 4, breakpoints: "", expected: "foo\nbars\nfoobars"},
    {name: "hyphen", input: "foo-foobar", limit: 4, breakpoints: "-", expected: "foo-\nfoobar"},
    {name: "emoji_breakpoint", input: "foo😃 foobar", limit: 4, breakpoints: "😃", expected: "foo😃\nfoobar"},
    {name: "wide_emoji_breakpoint", input: "foo🫧 foobar", limit: 4, breakpoints: "🫧", expected: "foo🫧\nfoobar"},
    {name: "space_breakpoint", input: "foo --bar", limit: 9, breakpoints: "-", expected: "foo --bar"},
    {name: "simple", input: "foo bars foobars", limit: 4, breakpoints: "", expected: "foo\nbars\nfoobars"},
    {name: "limit", input: "foo bar", limit: 5, breakpoints: "", expected: "foo\nbar"},
    {name: "remove white spaces", input: "foo    \nb   ar   ", limit: 4, breakpoints: "", expected: "foo\nb\nar"},
    {name: "white space trail width", input: "foo\nb\t a\n bar", limit: 4, breakpoints: "", expected: "foo\nb\t a\n bar"},
    {name: "explicit_line_break", input: "foo bar foo\n", limit: 4, breakpoints: "", expected: "foo\nbar\nfoo\n"},
    {name: "explicit_breaks", input: "\nfoo bar\n\n\nfoo\n", limit: 4, breakpoints: "", expected: "\nfoo\nbar\n\n\nfoo\n"},
    {name: "example", input: " This is a list: \n\n\t* foo\n\t* bar\n\n\n\t* foo  \nbar    ", limit: 6, breakpoints: "", expected: " This\nis a\nlist: \n\n\t* foo\n\t* bar\n\n\n\t* foo\nbar"},
    {name: "style_code_dont_affect_length", input: "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", limit: 7, breakpoints: "", expected: "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m"},
    {name: "style_code_dont_get_wrapped", input: "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m", limit: 3, breakpoints: "", expected: "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust\nanother\ntest\x1B[38;2;249;38;114m)\x1B[0m"},
    {name: "osc8_wrap", input: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\ สวัสดีสวัสดี\x1b]8;;\x1b\\", limit: 8, breakpoints: "", expected: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\\nสวัสดีสวัสดี\x1b]8;;\x1b\\"},
  ]

  it "wordwraps" do
    wordwrap_cases.each do |test_case|
      Ansi.wordwrap(test_case[:input], test_case[:limit], test_case[:breakpoints]).should eq test_case[:expected]
    end
  end

  it "wraps with wordwrap semantics" do
    input = "the quick brown foxxxxxxxxxxxxxxxx jumped over the lazy dog."
    limit = 16
    Ansi.wrap(input, limit, "").should eq "the quick brown\nfoxxxxxxxxxxxxxx\nxx jumped over\nthe lazy dog."
  end

  wrap_cases = [
    {
      name:     "simple",
      input:    "I really \x1B[38;2;249;38;114mlove\x1B[0m Go!",
      expected: "I really\n\x1B[38;2;249;38;114mlove\x1B[0m Go!",
      width:    8,
    },
    {name: "passthrough", input: "hello world", expected: "hello world", width: 11},
    {name: "asian", input: "こんにち", expected: "こんに\nち", width: 7},
    {name: "emoji", input: "😃👰🏻‍♀️🫧", expected: "😃\n👰🏻‍♀️\n🫧", width: 2},
    {name: "long style", input: "\x1B[38;2;249;38;114ma really long string\x1B[0m", expected: "\x1B[38;2;249;38;114ma really\nlong\nstring\x1B[0m", width: 10},
    {name: "long style nbsp", input: "\x1B[38;2;249;38;114ma really\u00a0long string\x1B[0m", expected: "\x1b[38;2;249;38;114ma\nreally\u00a0lon\ng string\x1b[0m", width: 10},
    {name: "longer", input: "the quick brown foxxxxxxxxxxxxxxxx jumped over the lazy dog.", expected: "the quick brown\nfoxxxxxxxxxxxxxx\nxx jumped over\nthe lazy dog.", width: 16},
    {
      name:     "longer asian",
      input:    "猴 猴 猴猴 猴猴猴猴猴猴猴猴猴 猴猴猴 猴猴 猴’ 猴猴 猴.",
      expected: "猴 猴 猴猴\n猴猴猴猴猴猴猴猴\n猴 猴猴猴 猴猴\n猴’ 猴猴 猴.",
      width:    16,
    },
    {
      name:     "long input",
      input:    "Rotated keys for a-good-offensive-cheat-code-incorporated/animal-like-law-on-the-rocks.",
      expected: "Rotated keys for a-good-offensive-cheat-code-incorporated/animal-like-law-\non-the-rocks.",
      width:    76,
    },
    {
      name:     "long input2",
      input:    "Rotated keys for a-good-offensive-cheat-code-incorporated/crypto-line-operating-system.",
      expected: "Rotated keys for a-good-offensive-cheat-code-incorporated/crypto-line-\noperating-system.",
      width:    76,
    },
    {name: "hyphen breakpoint", input: "a-good-offensive-cheat-code", expected: "a-good-\noffensive-\ncheat-code", width: 10},
    {name: "exact", input: "\x1b[91mfoo\x1b[0", expected: "\x1b[91mfoo\x1b[0", width: 3},
    {name: "extra space", input: "foo ", expected: "foo", width: 3},
    {name: "extra space style", input: "\x1b[mfoo \x1b[m", expected: "\x1b[mfoo\x1b[m", width: 3},
    {
      name:     "paragraph with styles",
      input:    "Lorem ipsum dolor \x1b[1msit\x1b[m amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. \x1b[31mUt enim\x1b[m ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea \x1b[38;5;200mcommodo consequat\x1b[m. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. \x1b[1;2;33mExcepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\x1b[m",
      expected: "Lorem ipsum dolor \x1b[1msit\x1b[m amet,\nconsectetur adipiscing elit,\nsed do eiusmod tempor\nincididunt ut labore et dolore\nmagna aliqua. \x1b[31mUt enim\x1b[m ad minim\nveniam, quis nostrud\nexercitation ullamco laboris\nnisi ut aliquip ex ea \x1b[38;5;200mcommodo\nconsequat\x1b[m. Duis aute irure\ndolor in reprehenderit in\nvoluptate velit esse cillum\ndolore eu fugiat nulla\npariatur. \x1b[1;2;33mExcepteur sint\noccaecat cupidatat non\nproident, sunt in culpa qui\nofficia deserunt mollit anim\nid est laborum.\x1b[m",
      width:    30,
    },
    {
      name:     "Multi Byte spaces",
      input:    "A\u202fB\u202fC\u202fDA\u205f\u205fB\u205fC\u205fDA\u3000B\u3000C\u3000D",
      expected: "A\u202fB\u202fC\nDA\u205f\u205fB\u205fC\nDA\u3000B\nC\u3000D",
      width:    7,
    },
    {name: "hyphen break", input: "foo-bar", expected: "foo-\nbar", width: 5},
    {name: "double space", input: "f  bar foobaz", expected: "f  bar\nfoobaz", width: 6},
    {name: "passthrough", input: "foobar\n ", expected: "foobar\n ", width: 0},
    {name: "pass", input: "foo", expected: "foo", width: 3},
    {name: "toolong", input: "foobarfoo", expected: "foob\narfo\no", width: 4},
    {name: "white space", input: "foo bar foo", expected: "foo\nbar\nfoo", width: 4},
    {name: "broken_at_spaces", input: "foo bars foobars", expected: "foo\nbars\nfoob\nars", width: 4},
    {name: "hyphen", input: "foob-foobar", expected: "foob\n-foo\nbar", width: 4},
    {name: "wide_emoji_breakpoint", input: "foo🫧 foobar", expected: "foo\n🫧\nfoob\nar", width: 4},
    {name: "space_breakpoint", input: "foo --bar", expected: "foo --bar", width: 9},
    {name: "simple", input: "foo bars foobars", expected: "foo\nbars\nfoob\nars", width: 4},
    {name: "limit", input: "foo bar", expected: "foo\nbar", width: 5},
    {name: "remove white spaces", input: "foo    \nb   ar   ", expected: "foo\nb\nar", width: 4},
    {name: "white space trail width", input: "foo\nb\t a\n bar", expected: "foo\nb\t a\n bar", width: 4},
    {name: "explicit_line_break", input: "foo bar foo\n", expected: "foo\nbar\nfoo\n", width: 4},
    {name: "explicit_breaks", input: "\nfoo bar\n\n\nfoo\n", expected: "\nfoo\nbar\n\n\nfoo\n", width: 4},
    {name: "example", input: " This is a list: \n\n\t* foo\n\t* bar\n\n\n\t* foo  \nbar    ", expected: " This\nis a\nlist: \n\n\t* foo\n\t* bar\n\n\n\t* foo\nbar", width: 6},
    {name: "style_code_dont_affect_length", input: "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", expected: "\x1B[38;2;249;38;114mfoo\x1B[0m\x1B[38;2;248;248;242m \x1B[0m\x1B[38;2;230;219;116mbar\x1B[0m", width: 7},
    {name: "style_code_dont_get_wrapped", input: "\x1B[38;2;249;38;114m(\x1B[0m\x1B[38;2;248;248;242mjust another test\x1B[38;2;249;38;114m)\x1B[0m", expected: "\x1b[38;2;249;38;114m(\x1b[0m\x1b[38;2;248;248;242mjust\nanother\ntest\x1b[38;2;249;38;114m)\x1b[0m", width: 7},
    {name: "osc8_wrap", input: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\ สวัสดีสวัสดี\x1b]8;;\x1b\\", expected: "สวัสดีสวัสดี\x1b]8;;https://example.com\x1b\\\nสวัสดีสวัสดี\x1b]8;;\x1b\\", width: 8},
    {name: "tab", input: "foo\tbar", expected: "foo\nbar", width: 3},
    {name: "Narrow NBSP", input: "0\u202f1\u202f2\u202f3\u202f4", expected: "0\u202f1\u202f2\u202f3\n4", width: 7},
    {name: "Paragraph Separator", input: "0\u20291\u20292\u20293\u20294", expected: "0\u20291\u20292\u20293\u20294", width: 7},
    {name: "Medium Mathematical Space", input: "0\u205f1\u205f2\u205f3\u205f4", expected: "0\u205f1\u205f2\u205f3\n4", width: 7},
    {name: "Ideagraphic space", input: "0\u30001\u30002\u30003\u3000", expected: "0\u30001\u30002\n3\u3000", width: 7},
    {
      name:     "japanese with white spaces narrow",
      input:    "耐許ヱヨカハ調出あゆ監件び理別よン國給災レホチ権輝モエフ会割もフ響3現エツ文時しだびほ経機ムイメフ敗文ヨク現義なさド請情ゆじょて憶主管州けでふく。排ゃわつげ美刊ヱミ出見ツ南者オ抜豆ハトロネ論索モネニイ任償スヲ話破リヤヨ秒止口イセソス止央のさ食周健でてつだ官送ト読聴遊容ひるべ。際ぐドらづ市居ネムヤ研校35岩6繹ごわク報拐イ革深52球ゃレスご究東スラ衝3間ラ録占たス。\n禁にンご忘康ざほぎル騰般ねど事超スんいう真表何カモ自浩ヲシミ図客線るふ静王ぱーま写村月掛焼詐面ぞゃ。昇強ごントほ価保キ族85岡モテ恋困ひりこな刊並せご出来ぼぎむう点目ヲウ止環公ニレ事応タス必書タメムノ当84無信升ちひょ。価ーぐ中客テサ告覧ヨトハ極整ラ得95稿はかラせ江利ス宏丸霊ミ考整ス静将ず業巨職ノラホ収嗅ざな。",
      expected: "耐許ヱヨカハ\n調出あゆ監件\nび理別よン國\n給災レホチ権\n輝モエフ会割\nもフ響3現エツ\n文時しだびほ\n経機ムイメフ\n敗文ヨク現義\nなさド請情ゆ\nじょて憶主管\n州けでふく。\n排ゃわつげ美\n刊ヱミ出見ツ\n南者オ抜豆ハ\nトロネ論索モ\nネニイ任償ス\nヲ話破リヤヨ\n秒止口イセソ\nス止央のさ食\n周健でてつだ\n官送ト読聴遊\n容ひるべ。際\nぐドらづ市居\nネムヤ研校35\n岩6繹ごわク報\n拐イ革深52球\nゃレスご究東\nスラ衝3間ラ録\n占たス。\n禁にンご忘康\nざほぎル騰般\nねど事超スん\nいう真表何カ\nモ自浩ヲシミ\n図客線るふ静\n王ぱーま写村\n月掛焼詐面ぞ\nゃ。昇強ごン\nトほ価保キ族8\n5岡モテ恋困ひ\nりこな刊並せ\nご出来ぼぎむ\nう点目ヲウ止\n環公ニレ事応\nタス必書タメ\nムノ当84無信\n升ちひょ。価\nーぐ中客テサ\n告覧ヨトハ極\n整ラ得95稿は\nかラせ江利ス\n宏丸霊ミ考整\nス静将ず業巨\n職ノラホ収嗅\nざな。",
      width:    13,
    },
    {
      name:     "japanese with white spaces wide",
      input:    "耐許ヱヨカハ調出あゆ監件び理別よン國給災レホチ権輝モエフ会割もフ響3現エツ文時しだびほ経機ムイメフ敗文ヨク現義なさド請情ゆじょて憶主管州けでふく。排ゃわつげ美刊ヱミ出見ツ南者オ抜豆ハトロネ論索モネニイ任償スヲ話破リヤヨ秒止口イセソス止央のさ食周健でてつだ官送ト読聴遊容ひるべ。際ぐドらづ市居ネムヤ研校35岩6繹ごわク報拐イ革深52球ゃレスご究東スラ衝3間ラ録占たス。\n禁にンご忘康ざほぎル騰般ねど事超スんいう真表何カモ自浩ヲシミ図客線るふ静王ぱーま写村月掛焼詐面ぞゃ。昇強ごントほ価保キ族85岡モテ恋困ひりこな刊並せご出来ぼぎむう点目ヲウ止環公ニレ事応タス必書タメムノ当84無信升ちひょ。価ーぐ中客テサ告覧ヨトハ極整ラ得95稿はかラせ江利ス宏丸霊ミ考整ス静将ず業巨職ノラホ収嗅ざな。",
      expected: "耐許ヱヨカハ調出あゆ監件び理別\nよン國給災レホチ権輝モエフ会割\nもフ響3現エツ文時しだびほ経機\nムイメフ敗文ヨク現義なさド請情\nゆじょて憶主管州けでふく。排ゃ\nわつげ美刊ヱミ出見ツ南者オ抜豆\nハトロネ論索モネニイ任償スヲ話\n破リヤヨ秒止口イセソス止央のさ\n食周健でてつだ官送ト読聴遊容ひ\nるべ。際ぐドらづ市居ネムヤ研校\n35岩6繹ごわク報拐イ革深52球ゃ\nレスご究東スラ衝3間ラ録占たス\n。\n禁にンご忘康ざほぎル騰般ねど事\n超スんいう真表何カモ自浩ヲシミ\n図客線るふ静王ぱーま写村月掛焼\n詐面ぞゃ。昇強ごントほ価保キ族\n85岡モテ恋困ひりこな刊並せご出\n来ぼぎむう点目ヲウ止環公ニレ事\n応タス必書タメムノ当84無信升ち\nひょ。価ーぐ中客テサ告覧ヨトハ\n極整ラ得95稿はかラせ江利ス宏丸\n霊ミ考整ス静将ず業巨職ノラホ収\n嗅ざな。",
      width:    30,
    },
  ]

  it "wraps" do
    wrap_cases.each do |test_case|
      Ansi.wrap(test_case[:input], test_case[:width], "").should eq test_case[:expected]
    end
  end
end
