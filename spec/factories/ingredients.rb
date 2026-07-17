FactoryBot.define do
  factory :ingredient do
    name { Faker::Food.unique.ingredient }
    unit_type { "weight" }
    category { "produce" }
  end
end
