require 'rails_helper'

RSpec.describe Analysis::CategoryBreakdown do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:date) { Date.new(2026, 3, 1) }

  subject(:result) { described_class.new(user: user, date: date).call }

  def create_txn(category:, amount:, posted_date: date)
    create(:transaction,
      user: user,
      account: account,
      category_primary: category,
      amount: amount,
      posted_date: posted_date,
      pending: false
    )
  end

  describe "#call" do
    before do
      create_txn(category: "FOOD_AND_DRINK", amount: 60.00)
      create_txn(category: "FOOD_AND_DRINK", amount: 40.00)
      create_txn(category: "TRAVEL", amount: 100.00)
      create_txn(category: "SHOPPING", amount: 50.00)
    end

    it "returns one entry per category" do
      expect(result.map { |r| r[:category] }).to match_array(%w[FOOD_AND_DRINK TRAVEL SHOPPING])
    end

    it "sums amounts per category" do
      food = result.find { |r| r[:category] == "FOOD_AND_DRINK" }
      expect(food[:total]).to eq(100.00)
    end

    it "calculates correct percentages" do
      # total = 250, TRAVEL = 100 → 40%
      travel = result.find { |r| r[:category] == "TRAVEL" }
      expect(travel[:percentage]).to eq(40.0)
    end

    it "sorts by total descending" do
      expect(result.first[:category]).to eq("FOOD_AND_DRINK")
    end

    it "excludes pending transactions" do
      create(:transaction, user: user, account: account,
        category_primary: "ENTERTAINMENT", amount: 200.00,
        posted_date: date, pending: true)
      categories = result.map { |r| r[:category] }
      expect(categories).not_to include("ENTERTAINMENT")
    end

    it "excludes transactions outside the month" do
      create_txn(category: "GROCERIES", amount: 999.00, posted_date: date - 1.month)
      categories = result.map { |r| r[:category] }
      expect(categories).not_to include("GROCERIES")
    end

    it "excludes negative amounts (credits/refunds)" do
      create_txn(category: "SHOPPING", amount: -20.00)
      shopping = result.find { |r| r[:category] == "SHOPPING" }
      expect(shopping[:total]).to eq(50.00)
    end

    context "when there are no transactions" do
      let(:empty_result) { described_class.new(user: create(:user), date: date).call }

      it "returns an empty array" do
        expect(empty_result).to eq([])
      end
    end

    context "when a transaction has no category" do
      before { create_txn(category: nil, amount: 25.00) }

      it "groups nil categories as Uncategorized" do
        categories = result.map { |r| r[:category] }
        expect(categories).to include("Uncategorized")
      end
    end
  end
end
