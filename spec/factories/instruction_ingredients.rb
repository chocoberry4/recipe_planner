FactoryBot.define do
  factory :instruction_ingredient do
    association :instruction
    association :recipe_ingredient
  end
end
