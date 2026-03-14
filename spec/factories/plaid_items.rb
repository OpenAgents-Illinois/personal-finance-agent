FactoryBot.define do
  factory :plaid_item do
    association :user
    plaid_item_id { "item-#{SecureRandom.hex(8)}" }
    access_token_encrypted { "encrypted-token-#{SecureRandom.hex(16)}" }
    institution_id { "ins_#{SecureRandom.hex(4)}" }
    institution_name { Faker::Company.name }
    last_sync_cursor { nil }
    last_synced_at { nil }
  end
end
