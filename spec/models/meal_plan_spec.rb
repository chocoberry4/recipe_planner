require 'rails_helper'

RSpec.describe MealPlan, type: :model do
  it "is valid with a recipe and no label" do
    meal_plan = build(:meal_plan, recipe: create(:recipe), label: nil)

    expect(meal_plan).to be_valid
  end

  it "is valid with a label and no recipe" do
    meal_plan = build(:meal_plan, recipe: nil, label: "Leftovers")

    expect(meal_plan).to be_valid
  end

  it "is invalid with neither a recipe nor a label" do
    meal_plan = build(:meal_plan, recipe: nil, label: nil)

    expect(meal_plan).not_to be_valid
  end

  it "requires a date" do
    meal_plan = build(:meal_plan, date: nil)

    expect(meal_plan).not_to be_valid
  end

  it "strips whitespace from the label and treats a blank label as absent" do
    meal_plan = build(:meal_plan, recipe: create(:recipe), label: "   ")
    meal_plan.valid?

    expect(meal_plan.label).to be_nil
  end
end
