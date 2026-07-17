FactoryBot.define do
  factory :recipe do
    title { Faker::Food.dish }
    description { Faker::Food.description }
    association :user
  end
end
