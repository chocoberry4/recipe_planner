FactoryBot.define do
  factory :meal_plan do
    association :user
    association :recipe
    date { Date.current }
    meal_type { "dinner" }
  end
end
