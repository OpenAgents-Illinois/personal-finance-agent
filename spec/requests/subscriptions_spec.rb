require 'rails_helper'

RSpec.describe "Subscriptions", type: :request do
  let(:user) { create(:user) }

  describe "GET /subscriptions" do
    context "when not authenticated" do
      it "redirects to login" do
        get subscriptions_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200 with no data" do
        get subscriptions_path
        expect(response).to have_http_status(:ok)
      end

      it "shows empty state when no recurring charges exist" do
        get subscriptions_path
        expect(response.body).to include("No recurring charges detected yet")
      end

      it "lists active recurring charges" do
        create(:recurring_charge, user: user, merchant_name: "Netflix", amount: 15.99, cadence: "monthly")
        get subscriptions_path
        expect(response.body).to include("Netflix")
        expect(response.body).to include("15.99")
      end

      it "does not show inactive charges" do
        create(:recurring_charge, user: user, merchant_name: "Spotify", active: false)
        get subscriptions_path
        expect(response.body).not_to include("Spotify")
      end

      it "shows the total monthly cost" do
        create(:recurring_charge, user: user, amount: 10.00, cadence: "monthly")
        create(:recurring_charge, user: user, amount: 120.00, cadence: "annual")
        get subscriptions_path
        # 10.00 + (120.00 / 12) = 20.00
        expect(response.body).to include("20.0")
      end

      it "displays cadence badges" do
        create(:recurring_charge, user: user, cadence: "monthly")
        create(:recurring_charge, user: user, cadence: "annual")
        get subscriptions_path
        expect(response.body).to include("Monthly")
        expect(response.body).to include("Annual")
      end
    end
  end
end
