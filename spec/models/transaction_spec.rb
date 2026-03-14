require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    subject { build(:transaction) }

    it { is_expected.to validate_presence_of(:plaid_transaction_id) }
    it { is_expected.to validate_uniqueness_of(:plaid_transaction_id) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let(:plaid_item) { create(:plaid_item, user: user) }
    let(:account) { create(:account, user: user, plaid_item: plaid_item) }

    it ".posted returns only non-pending transactions" do
      posted = create(:transaction, user: user, account: account, pending: false)
      pending = create(:transaction, user: user, account: account, pending: true)
      expect(Transaction.posted).to include(posted)
      expect(Transaction.posted).not_to include(pending)
    end

    it ".for_month returns transactions in the given month" do
      this_month = create(:transaction, user: user, account: account, posted_date: Date.current)
      last_month = create(:transaction, user: user, account: account, posted_date: 1.month.ago.to_date)
      expect(Transaction.for_month(Date.current)).to include(this_month)
      expect(Transaction.for_month(Date.current)).not_to include(last_month)
    end
  end
end
