FactoryBot.define do
  factory :shopping_item do
    association :user
    name { "flour" }
    quantity { nil }
    unit { nil }
    checked { false }
  end
end
