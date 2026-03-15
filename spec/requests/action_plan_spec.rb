require 'rails_helper'

RSpec.describe "ActionPlan", type: :request do
  let(:user) { create(:user) }

  describe "GET /action_plan" do
    context "when not authenticated" do
      it "redirects to login" do
        get action_plan_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns 200 with no data" do
        get action_plan_path
        expect(response).to have_http_status(:ok)
      end

      it "shows empty state when no recommendations exist" do
        get action_plan_path
        expect(response.body).to include("No recommendations yet")
      end

      it "shows savings opportunities when transactions exist" do
        account = create(:account, user: user)
        create(:transaction, account: account, user: user,
               amount: 200.00, category_primary: "FOOD_AND_DRINK",
               posted_date: Date.current, pending: false)

        get action_plan_path
        expect(response.body).to include("Savings Opportunities")
        expect(response.body).to include("Food And Drink")
      end

      it "shows recommendations when present" do
        create(:recommendation, user: user, content: "Reduce dining spend by cooking at home.")
        get action_plan_path
        expect(response.body).to include("Reduce dining spend by cooking at home.")
      end

      it "shows total potential savings" do
        account = create(:account, user: user)
        create(:transaction, account: account, user: user,
               amount: 500.00, category_primary: "SHOPPING",
               posted_date: Date.current, pending: false)

        get action_plan_path
        expect(response.body).to include("Potential Monthly Savings")
      end
    end
  end
end
