module ClickableExample
  UNCAPPED = " of a an and 'n' "

  ADJECTIVES = [
    "a hot", "a cute", "a fresh", "a nice", "a lovely",
    "an eager", "a soft", "an expensive", "a new", "an old", "a happy",
    "a messy", "a good", "a bad", "a cheesy", "a friendly", "a free",
    "a cold", "a gorgeous", "a glamorous", "a handsome", "an exquisite",
    "a tantalizing", "a suspicious", "an american", "a wooden", "a golden",
    "a dirty", "a hairy", "a lukewarm", "a burning hot", "a shiny",
    "a rogue", "a green", "a late night", "a mass produced", "a handmade",
    "a wild", "a clean", "a rugged", "the #1", "the best", "the worst",
    "a famous", "an infamous", "a clever", "a microwaved", "a 3D printed",
    "your favorite", "your least favorite", "someone's", "a precious",
    "a fake", "a genuine", "a bejeweled", "a good-smelling",
  ]

  NOUNS = [
    "pear", "banana", "bowl of ramen", "currywurst", "quince",
    "pie", "cake", "burrito", "sushi", "basket of fish 'n' chips", "burger",
    "kohlrabi", "pineapple", "cantaloupe", "sausage roll", "yuzu",
    "grapefruit", "espresso shot", "sandwich", "bowl of chow mein", "lemon",
    "cup of coffee", "bottle of hot sauce", "can of beer", "glass of wine",
    "muffin", "bagel", "glass of champagne", "bottle of rose", "pengu",
    "badger", "mango", "okonomiyaki", "meatball", "box of wine",
    "artichoke", "TUI", "linux distro", "dotfile", "weisswurst", "computer",
  ]

  @@adjectives : Array(String) = ADJECTIVES.shuffle
  @@nouns : Array(String) = NOUNS.shuffle
  @@word_mutex : Mutex = Mutex.new

  def self.next_random_word : String
    @@word_mutex.synchronize do
      @@adjectives = cycle(@@adjectives)
      @@nouns = cycle(@@nouns)
      capitalize("#{@@adjectives[0]} #{@@nouns[0]}")
    end
  end

  private def self.capitalize(input : String) : String
    words = input.split(/\s+/)
    words.each_with_index do |word, idx|
      if idx > 0 && UNCAPPED.includes?(" #{word.downcase} ")
        words[idx] = word.downcase
      else
        words[idx] = word.capitalize
      end
    end
    words.join(" ")
  end

  private def self.cycle(stack : Array(String)) : Array(String)
    return stack if stack.empty?
    stack[1..] + [stack[0]]
  end
end
