require 'rails_helper'

RSpec.describe "Plaid", type: :request do
  let(:user) { create(:user) }

  describe "POST /plaid/link_token" do
    context "when authenticated" do
      before { sign_in user }

      let(:plaid_client_double) { instance_double(Integrations::PlaidClient) }

      before do
        allow(Integrations::PlaidClient).to receive(:new).and_return(plaid_client_double)
      end

      it "returns a link token" do
        fake_response = double("link_token_response", link_token: "link-sandbox-abc123")
        allow(plaid_client_double).to receive(:create_link_token).with(user_id: user.id).and_return(fake_response)

        post link_token_path
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["link_token"]).to eq("link-sandbox-abc123")
      end

      it "returns 503 when Plaid API fails" do
        allow(plaid_client_double).to receive(:create_link_token).and_raise(Plaid::ApiError.new)

        post link_token_path
        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to be_present
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post link_token_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /plaid/exchange_public_token" do
    context "when authenticated" do
      before { sign_in user }

      let(:plaid_client_double) { instance_double(Integrations::PlaidClient) }
      let(:exchange_response) { double("exchange_response", access_token: "access-sandbox-xyz", item_id: "item-abc") }

      before do
        allow(Integrations::PlaidClient).to receive(:new).and_return(plaid_client_double)
        allow(plaid_client_double).to receive(:exchange_public_token).and_return(exchange_response)
        allow(SyncTransactionsJob).to receive(:perform_later)
      end

      it "returns the plaid_item_id with 201" do
        post exchange_public_token_path, params: { public_token: "public-sandbox-token" }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["plaid_item_id"]).to eq("item-abc")
      end

      it "returns 400 when public_token param is missing" do
        post exchange_public_token_path
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to be_present
      end

      it "returns 503 when Plaid API fails" do
        allow(plaid_client_double).to receive(:exchange_public_token).and_raise(Plaid::ApiError.new)
        post exchange_public_token_path, params: { public_token: "public-sandbox-token" }
        expect(response).to have_http_status(:service_unavailable)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post exchange_public_token_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
