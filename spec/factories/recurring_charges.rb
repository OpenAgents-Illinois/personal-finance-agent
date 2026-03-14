FactoryBot.define do
  factory :recurring_charge do
    association :user
    merchant_name { Faker::Company.name }
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    cadence { "monthly" }
    last_charged_on { 1.month.ago.to_date }
    active { true }
  end
end
