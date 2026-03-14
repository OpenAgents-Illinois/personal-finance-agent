FactoryBot.define do
  factory :account do
    association :user
    association :plaid_item
    plaid_account_id { "account-#{SecureRandom.hex(8)}" }
    name { Faker::Bank.name }
    account_type { "depository" }
    account_subtype { "checking" }
    current_balance { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    available_balance { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    iso_currency_code { "USD" }
  end
end
