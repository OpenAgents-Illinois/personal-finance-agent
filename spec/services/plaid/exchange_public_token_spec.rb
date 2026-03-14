require 'rails_helper'

RSpec.describe Plaid::ExchangePublicToken do
  let(:user) { create(:user) }
  let(:public_token) { "public-sandbox-token" }
  let(:plaid_client_double) { instance_double(Integrations::PlaidClient) }
  let(:exchange_response) do
    double("exchange_response", access_token: "access-sandbox-xyz", item_id: "item-123")
  end

  subject(:service) { described_class.new(user: user, public_token: public_token) }

  before do
    allow(Integrations::PlaidClient).to receive(:new).and_return(plaid_client_double)
    allow(plaid_client_double).to receive(:exchange_public_token)
      .with(public_token: public_token)
      .and_return(exchange_response)
    allow(SyncTransactionsJob).to receive(:perform_later)
  end

  describe "#call" do
    it "creates a PlaidItem for the user" do
      expect { service.call }.to change(PlaidItem, :count).by(1)

      item = PlaidItem.last
      expect(item.user).to eq(user)
      expect(item.plaid_item_id).to eq("item-123")
    end

    it "encrypts the access token" do
      service.call

      item = PlaidItem.last
      expect(item.access_token_encrypted).not_to eq("access-sandbox-xyz")
      expect(item.access_token_encrypted).to be_present
    end

    it "enqueues SyncTransactionsJob" do
      service.call

      item = PlaidItem.last
      expect(SyncTransactionsJob).to have_received(:perform_later).with(item.id)
    end

    it "returns the PlaidItem" do
      result = service.call
      expect(result).to be_a(PlaidItem)
      expect(result.plaid_item_id).to eq("item-123")
    end

    context "when PlaidItem already exists (re-link)" do
      before { create(:plaid_item, user: user, plaid_item_id: "item-123") }

      it "does not create a duplicate" do
        expect { service.call }.not_to change(PlaidItem, :count)
      end

      it "does not enqueue SyncTransactionsJob again" do
        service.call
        expect(SyncTransactionsJob).not_to have_received(:perform_later)
      end
    end
  end
end
