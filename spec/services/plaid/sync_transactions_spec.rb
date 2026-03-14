require 'rails_helper'

RSpec.describe Plaid::SyncTransactions do
  let(:user) { create(:user) }
  let(:plaid_item) { create(:plaid_item, user: user) }
  let(:plaid_client_double) { instance_double(Integrations::PlaidClient) }

  let(:account_double) do
    double("plaid_account",
      account_id: "acct-001",
      name: "Checking",
      type: "depository",
      subtype: "checking",
      balances: double(current: 1000.00, available: 950.00, iso_currency_code: "USD")
    )
  end

  let(:txn_double) do
    double("plaid_txn",
      transaction_id: "txn-001",
      account_id: "acct-001",
      name: "Coffee Shop",
      amount: 4.50,
      date: Date.today,
      authorized_date: Date.yesterday,
      pending: false,
      merchant_name: "Blue Bottle",
      personal_finance_category: double(primary: "FOOD_AND_DRINK", detailed: "FOOD_AND_DRINK_COFFEE"),
      to_hash: {}
    )
  end

  let(:sync_response) do
    double("sync_response",
      accounts: [ account_double ],
      added: [ txn_double ],
      modified: [],
      removed: [],
      next_cursor: "cursor-abc",
      has_more: false
    )
  end

  before do
    allow(Integrations::PlaidClient).to receive(:new).and_return(plaid_client_double)
    allow(Plaid::TokenEncryptor).to receive(:decrypt).and_return("access-sandbox-xyz")
    allow(plaid_client_double).to receive(:sync_transactions).and_return(sync_response)
    allow(txn_double).to receive(:respond_to?).with(:personal_finance_category).and_return(true)
    allow(txn_double).to receive(:respond_to?).with(:accounts).and_return(true)
    allow(sync_response).to receive(:respond_to?).with(:accounts).and_return(true)
  end

  subject(:service) { described_class.new(plaid_item) }

  describe "#call" do
    it "upserts accounts from the response" do
      expect { service.call }.to change(Account, :count).by(1)
      expect(Account.last.plaid_account_id).to eq("acct-001")
    end

    it "creates new transactions" do
      service.call
      expect(Transaction.count).to eq(1)
      txn = Transaction.last
      expect(txn.plaid_transaction_id).to eq("txn-001")
      expect(txn.name).to eq("Coffee Shop")
      expect(txn.amount).to eq(4.50)
    end

    it "updates last_sync_cursor and last_synced_at on the PlaidItem" do
      service.call
      plaid_item.reload
      expect(plaid_item.last_sync_cursor).to eq("cursor-abc")
      expect(plaid_item.last_synced_at).to be_present
    end

    it "passes the existing cursor to PlaidClient on subsequent syncs" do
      plaid_item.update!(last_sync_cursor: "cursor-prev")
      expect(plaid_client_double).to receive(:sync_transactions)
        .with(access_token: "access-sandbox-xyz", cursor: "cursor-prev")
        .and_return(sync_response)
      service.call
    end

    context "with modified transactions" do
      let(:existing_account) { create(:account, user: user, plaid_item: plaid_item, plaid_account_id: "acct-001") }
      let(:existing_txn) { create(:transaction, user: user, account: existing_account, plaid_transaction_id: "txn-001", name: "Old Name") }

      let(:modified_txn) do
        double("modified_txn",
          transaction_id: "txn-001",
          account_id: "acct-001",
          name: "New Name",
          amount: 5.00,
          date: Date.today,
          authorized_date: Date.yesterday,
          pending: false,
          merchant_name: "Blue Bottle",
          personal_finance_category: double(primary: "FOOD_AND_DRINK", detailed: "FOOD_AND_DRINK_COFFEE"),
          to_hash: {}
        )
      end

      before do
        existing_txn
        allow(modified_txn).to receive(:respond_to?).with(:personal_finance_category).and_return(true)
        allow(sync_response).to receive(:added).and_return([])
        allow(sync_response).to receive(:modified).and_return([ modified_txn ])
      end

      it "updates the existing transaction" do
        service.call
        expect(existing_txn.reload.name).to eq("New Name")
      end
    end

    context "with removed transactions" do
      let(:existing_account) { create(:account, user: user, plaid_item: plaid_item, plaid_account_id: "acct-001") }
      let!(:existing_txn) { create(:transaction, user: user, account: existing_account, plaid_transaction_id: "txn-001") }

      let(:removed_double) { double("removed", transaction_id: "txn-001") }

      before do
        allow(sync_response).to receive(:added).and_return([])
        allow(sync_response).to receive(:removed).and_return([ removed_double ])
      end

      it "destroys removed transactions" do
        expect { service.call }.to change(Transaction, :count).by(-1)
      end
    end

    context "when has_more is true" do
      let(:second_response) do
        double("sync_response_2",
          accounts: [],
          added: [],
          modified: [],
          removed: [],
          next_cursor: "cursor-final",
          has_more: false
        )
      end

      before do
        allow(sync_response).to receive(:has_more).and_return(true)
        allow(second_response).to receive(:respond_to?).with(:accounts).and_return(true)
        allow(plaid_client_double).to receive(:sync_transactions)
          .and_return(sync_response, second_response)
      end

      it "pages through all results" do
        expect(plaid_client_double).to receive(:sync_transactions).twice
        service.call
        expect(plaid_item.reload.last_sync_cursor).to eq("cursor-final")
      end
    end
  end
end
