require 'rails_helper'

RSpec.describe IngredientLineParser do
  def parse(line)
    described_class.parse(line)
  end

  it "parses a mixed numeric fraction with a preparation note" do
    result = parse("1 1/2 cups all-purpose flour, sifted")

    expect(result.quantity).to eq(1.5)
    expect(result.unit).to eq("cups")
    expect(result.name).to eq("all-purpose flour")
    expect(result.preparation).to eq("sifted")
  end

  it "parses a leading unicode fraction with no whole number" do
    result = parse("½ cup sugar")

    expect(result.quantity).to eq(0.5)
    expect(result.unit).to eq("cup")
    expect(result.name).to eq("sugar")
    expect(result.preparation).to be_nil
  end

  it "parses a whole number glued to a unicode fraction" do
    result = parse("1½ cups milk")

    expect(result.quantity).to eq(1.5)
    expect(result.unit).to eq("cups")
    expect(result.name).to eq("milk")
  end

  it "parses a simple numeric fraction with no whole number" do
    result = parse("1/2 tsp salt")

    expect(result.quantity).to eq(0.5)
    expect(result.unit).to eq("tsp")
    expect(result.name).to eq("salt")
  end

  it "parses a decimal quantity" do
    result = parse("2.5 cups broth")

    expect(result.quantity).to eq(2.5)
    expect(result.unit).to eq("cups")
    expect(result.name).to eq("broth")
  end

  it "strips a leading 'of' after the unit" do
    result = parse("1 pinch of salt")

    expect(result.quantity).to eq(1.0)
    expect(result.unit).to eq("pinch")
    expect(result.name).to eq("salt")
  end

  it "handles a missing unit" do
    result = parse("2 eggs")

    expect(result.quantity).to eq(2.0)
    expect(result.unit).to be_nil
    expect(result.name).to eq("eggs")
  end

  it "treats a bare 'x' count marker as the unit" do
    result = parse("1 x onion")

    expect(result.quantity).to eq(1.0)
    expect(result.unit).to eq("x")
    expect(result.name).to eq("onion")
  end

  it "does not mistake a non-unit descriptor for a unit" do
    result = parse("3 large eggs")

    expect(result.quantity).to eq(3.0)
    expect(result.unit).to be_nil
    expect(result.name).to eq("large eggs")
  end

  it "handles a missing quantity and unit" do
    result = parse("Salt to taste")

    expect(result.quantity).to be_nil
    expect(result.unit).to be_nil
    expect(result.name).to eq("Salt to taste")
    expect(result.preparation).to be_nil
  end

  it "handles a missing quantity with a preparation note" do
    result = parse("Salt, to taste")

    expect(result.quantity).to be_nil
    expect(result.unit).to be_nil
    expect(result.name).to eq("Salt")
    expect(result.preparation).to eq("to taste")
  end

  it "handles a prep-note-free line" do
    result = parse("2 cups flour")

    expect(result.quantity).to eq(2.0)
    expect(result.unit).to eq("cups")
    expect(result.name).to eq("flour")
    expect(result.preparation).to be_nil
  end

  it "handles a multi-word preparation note" do
    result = parse("1 cup onion, finely chopped")

    expect(result.quantity).to eq(1.0)
    expect(result.unit).to eq("cup")
    expect(result.name).to eq("onion")
    expect(result.preparation).to eq("finely chopped")
  end

  it "strips a trailing parenthetical note not preceded by a comma" do
    result = parse("1 cup tomato passata (aka tomato puree)")

    expect(result.name).to eq("tomato passata")
    expect(result.preparation).to eq("aka tomato puree")
  end

  it "strips a doubled/nested parenthetical footnote marker" do
    result = parse("1 cup heavy cream ((Note 5))")

    expect(result.name).to eq("heavy cream")
    expect(result.preparation).to eq("Note 5")
  end

  it "strips a parenthetical aside sitting between the unit and the name" do
    result = parse("2 tbsp (30 g) ghee or butter")

    expect(result.quantity).to eq(2.0)
    expect(result.unit).to eq("tbsp")
    expect(result.name).to eq("ghee or butter")
    expect(result.preparation).to eq("30 g")
  end

  it "combines a parenthetical aside with an existing comma preparation note" do
    result = parse("1 cup onion (yellow), finely chopped")

    expect(result.name).to eq("onion")
    expect(result.preparation).to eq("finely chopped; yellow")
  end

  it "returns all-nil fields for a blank line" do
    result = parse("   ")

    expect(result.quantity).to be_nil
    expect(result.unit).to be_nil
    expect(result.name).to be_nil
    expect(result.preparation).to be_nil
  end
end
