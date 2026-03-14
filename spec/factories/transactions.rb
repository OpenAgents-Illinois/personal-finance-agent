FactoryBot.define do
  factory :transaction do
    association :user
    association :account
    plaid_transaction_id { "txn-#{SecureRandom.hex(8)}" }
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    name { Faker::Company.name }
    merchant_name { Faker::Company.name }
    pending { false }
    authorized_date { 3.days.ago.to_date }
    posted_date { 2.days.ago.to_date }
    category_primary { "FOOD_AND_DRINK" }
    category_detailed { "FOOD_AND_DRINK_RESTAURANTS" }
    raw_payload_json { {} }
  end
end
