require 'rails_helper'

RSpec.describe PlaidItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:accounts).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:plaid_item) }

    it { is_expected.to validate_presence_of(:plaid_item_id) }
    it { is_expected.to validate_uniqueness_of(:plaid_item_id) }
    it { is_expected.to validate_presence_of(:access_token_encrypted) }
  end
end
