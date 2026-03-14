require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    context "when not authenticated" do
      it "redirects to login" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200 with no data" do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it "shows connect bank banner when user has no accounts" do
        get root_path
        expect(response.body).to include("Connect your bank to get started")
      end

      it "shows spending data when user has transactions" do
        account = create(:account, user: user)
        create(:transaction, account: account, user: user,
               amount: 50.00, category_primary: "FOOD_AND_DRINK",
               posted_date: Date.current, pending: false)

        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Food And Drink")
      end

      it "shows latest recommendation when present" do
        create(:recommendation, user: user, content: "Cut your coffee budget.")
        get root_path
        expect(response.body).to include("Cut your coffee budget.")
      end

      it "hides connect banner when user has accounts" do
        create(:account, user: user)
        get root_path
        expect(response.body).not_to include("Connect your bank to get started")
      end
    end
  end
end
