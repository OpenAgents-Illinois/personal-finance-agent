require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:plaid_item) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:account) }

    it { is_expected.to validate_presence_of(:plaid_account_id) }
    it { is_expected.to validate_uniqueness_of(:plaid_account_id) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
