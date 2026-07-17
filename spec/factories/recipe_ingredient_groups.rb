FactoryBot.define do
  factory :recipe_ingredient_group do
    association :recipe
    sequence(:name) { |n| "Group #{n}" }
    position { 1 }
  end
end
