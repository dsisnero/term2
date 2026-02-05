require "../../src/view"

module Term2
  module SpecView
    def self.content(view : String) : String
      view
    end

    def self.content(view : View) : String
      view.content
    end
  end
end
