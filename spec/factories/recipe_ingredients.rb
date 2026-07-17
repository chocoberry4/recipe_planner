FactoryBot.define do
  factory :recipe_ingredient do
    association :recipe
    association :ingredient
    quantity { 1 }
    unit { "cup" }
    preparation { nil }
    position { 1 }
  end
end
