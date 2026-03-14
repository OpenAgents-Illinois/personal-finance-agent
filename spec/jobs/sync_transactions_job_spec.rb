require 'rails_helper'

RSpec.describe SyncTransactionsJob do
  let(:user) { create(:user) }
  let(:plaid_item) { create(:plaid_item, user: user) }
  let(:sync_service_double) { instance_double(Plaid::SyncTransactions, call: nil) }

  before do
    allow(Plaid::SyncTransactions).to receive(:new).and_return(sync_service_double)
  end

  describe "#perform" do
    it "calls SyncTransactions with the PlaidItem" do
      described_class.perform_now(plaid_item.id)
      expect(Plaid::SyncTransactions).to have_received(:new).with(plaid_item)
      expect(sync_service_double).to have_received(:call)
    end

    it "discards the job if the PlaidItem no longer exists" do
      expect {
        described_class.perform_now(0)
      }.not_to raise_error
    end
  end
end
