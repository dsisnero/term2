require "random"

struct RandomItemGenerator
  getter titles : Array(String)
  getter descs : Array(String)
  property title_index : Int32 = 0
  property desc_index : Int32 = 0

  def initialize
    @titles = [
      "Artichoke",
      "Baking Flour",
      "Bananas",
      "Barley",
      "Bean Sprouts",
      "Bitter Melon",
      "Black Cod",
      "Blood Orange",
      "Brown Sugar",
      "Cashew Apple",
      "Cashews",
      "Cat Food",
      "Coconut Milk",
      "Cucumber",
      "Curry Paste",
      "Currywurst",
      "Dill",
      "Dragonfruit",
      "Dried Shrimp",
      "Eggs",
      "Fish Cake",
      "Furikake",
      "Garlic",
      "Gherkin",
      "Ginger",
      "Granulated Sugar",
      "Grapefruit",
      "Green Onion",
      "Hazelnuts",
      "Heavy whipping cream",
      "Honey Dew",
      "Horseradish",
      "Jicama",
      "Kohlrabi",
      "Leeks",
      "Lentils",
      "Licorice Root",
      "Meyer Lemons",
      "Milk",
      "Molasses",
      "Muesli",
      "Nectarine",
      "Niagamo Root",
      "Nopal",
      "Nutella",
      "Oat Milk",
      "Oatmeal",
      "Olives",
      "Papaya",
      "Party Gherkin",
      "Peppers",
      "Persian Lemons",
      "Pickle",
      "Pineapple",
      "Plantains",
      "Pocky",
      "Powdered Sugar",
      "Quince",
      "Radish",
      "Ramps",
      "Star Anise",
      "Sweet Potato",
      "Tamarind",
      "Unsalted Butter",
      "Watermelon",
      "Weißwurst",
      "Yams",
      "Yeast",
      "Yuzu",
      "Snow Peas",
    ]

    @descs = [
      "A little weird",
      "Bold flavor",
      "Can’t get enough",
      "Delectable",
      "Expensive",
      "Expired",
      "Exquisite",
      "Fresh",
      "Gimme",
      "In season",
      "Kind of spicy",
      "Looks fresh",
      "Looks good to me",
      "Maybe not",
      "My favorite",
      "Oh my",
      "On sale",
      "Organic",
      "Questionable",
      "Really fresh",
      "Refreshing",
      "Salty",
      "Scrumptious",
      "Delectable",
      "Slightly sweet",
      "Smells great",
      "Tasty",
      "Too ripe",
      "At last",
      "What?",
      "Wow",
      "Yum",
      "Maybe",
      "Sure, why not?",
    ]

    @titles.shuffle!
    @descs.shuffle!
  end

  def next : FancyItem
    title = @titles[@title_index]
    desc = @descs[@desc_index]

    @title_index += 1
    @title_index = 0 if @title_index >= @titles.size

    @desc_index += 1
    @desc_index = 0 if @desc_index >= @descs.size

    FancyItem.new(title, desc)
  end
end
