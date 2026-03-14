require 'rails_helper'

RSpec.describe Integrations::PlaidClient do
  let(:plaid_api_double) { instance_double(Plaid::PlaidApi) }
  let(:client) do
    allow(Plaid::PlaidApi).to receive(:new).and_return(plaid_api_double)
    described_class.new
  end

  before do
    stub_const("ENV", ENV.to_h.merge(
      "PLAID_CLIENT_ID" => "test-client-id",
      "PLAID_SECRET" => "test-secret",
      "PLAID_ENV" => "sandbox"
    ))
  end

  describe "#create_link_token" do
    it "calls the Plaid API with correct user and products" do
      response = double("link_token_response", link_token: "link-sandbox-abc123")
      expect(plaid_api_double).to receive(:link_token_create) do |request|
        expect(request.user.client_user_id).to eq("42")
        expect(request.products).to eq([ "transactions" ])
        expect(request.country_codes).to eq([ "US" ])
        response
      end

      result = client.create_link_token(user_id: 42)
      expect(result.link_token).to eq("link-sandbox-abc123")
    end
  end

  describe "#exchange_public_token" do
    it "exchanges a public token and returns access token response" do
      response = double("exchange_response", access_token: "access-sandbox-xyz", item_id: "item-123")
      expect(plaid_api_double).to receive(:item_public_token_exchange) do |request|
        expect(request.public_token).to eq("public-sandbox-token")
        response
      end

      result = client.exchange_public_token(public_token: "public-sandbox-token")
      expect(result.access_token).to eq("access-sandbox-xyz")
      expect(result.item_id).to eq("item-123")
    end
  end

  describe "#sync_transactions" do
    it "calls transactions_sync with access token and cursor" do
      response = double("sync_response", added: [], modified: [], removed: [], next_cursor: "cursor-2", has_more: false)
      expect(plaid_api_double).to receive(:transactions_sync) do |request|
        expect(request.access_token).to eq("access-sandbox-xyz")
        expect(request.cursor).to eq("cursor-1")
        response
      end

      result = client.sync_transactions(access_token: "access-sandbox-xyz", cursor: "cursor-1")
      expect(result.has_more).to be false
    end

    it "works without a cursor for initial sync" do
      response = double("sync_response", added: [], modified: [], removed: [], next_cursor: "cursor-1", has_more: false)
      expect(plaid_api_double).to receive(:transactions_sync) do |request|
        expect(request.cursor).to be_nil
        response
      end

      client.sync_transactions(access_token: "access-sandbox-xyz")
    end
  end

  describe "#get_accounts" do
    it "fetches accounts for the given access token" do
      account = double("account", account_id: "acc-1", name: "Checking", balances: double(current: 1000.00))
      response = double("accounts_response", accounts: [ account ])
      expect(plaid_api_double).to receive(:accounts_get) do |request|
        expect(request.access_token).to eq("access-sandbox-xyz")
        response
      end

      result = client.get_accounts(access_token: "access-sandbox-xyz")
      expect(result.accounts.first.name).to eq("Checking")
    end
  end
end
