FactoryBot.define do
  factory :instruction do
    association :recipe
    sequence(:step_number) { |n| n }
    description { Faker::Lorem.sentence }
    duration_minutes { 5 }
  end
end
