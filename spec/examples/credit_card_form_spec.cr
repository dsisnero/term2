ENV["TERM2_REQUIRE_ONLY"] = "1"
require "../spec_helper"
require "../../examples/bubbletea/credit-card-form/main"

describe "Example: credit-card-form" do
  it "validates and cycles inputs" do
    model = CreditCardModel.new
    model.init

    # Fill CCN with valid grouping
    "4505 1234 5678 9012".each_char do |ch|
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    # Tab to EXP
    model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Tab)))
    "12/34".each_char do |ch|
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    # Tab to CVV
    model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Tab)))
    "123".each_char do |ch|
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end

    model.inputs[Field::CCN.value].value.should eq("4505 1234 5678 9012")
    model.inputs[Field::EXP.value].value.should eq("12/34")
    model.inputs[Field::CVV.value].value.should eq("123")
  end

  it "rejects invalid input for CCN/EXP/CVV" do
    model = CreditCardModel.new
    model.init

    # Invalid CCN (too long)
    "4505 1234 5678 9012 9999".each_char do |ch|
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    model.inputs[Field::CCN.value].value.should_not eq("4505 1234 5678 9012 9999")

    # Move to EXP and try invalid slash placement
    model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Tab)))
    "1/234".each_char do |ch|
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    model.inputs[Field::EXP.value].value.should_not eq("1/234")

    # Move to CVV and try letters
    model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Tab)))
    "12a".each_char do |ch|
      model, _ = model.update(Term2::KeyMsg.new(Term2::Key.new(ch)))
    end
    model.inputs[Field::CVV.value].value.should_not eq("12a")
  end

  it "rejects invalid input via teatest harness" do
    tm = Term2::Teatest::TestModel(CreditCardModel).new(CreditCardModel.new, Term2::Teatest.with_initial_term_size(40, 12))
    tm.send(Term2::WindowSizeMsg.new(40, 12))

    # Too-long CCN should be clipped/ignored by validator
    tm.type("4505 1234 5678 9012 9999")
    tm.send(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Tab)))
    # Invalid EXP slash placement
    tm.type("1/234")
    tm.send(Term2::KeyMsg.new(Term2::Key.new(Term2::KeyType::Tab)))
    # Non-numeric CVV
    tm.type("12a")
    tm.quit

    final = tm.final_model
    final.inputs[Field::CCN.value].value.should_not eq("4505 1234 5678 9012 9999")
    final.inputs[Field::EXP.value].value.should_not eq("1/234")
    final.inputs[Field::CVV.value].value.should_not eq("12a")
  end
end
