require 'rails_helper'

RSpec.describe Analysis::SpendingSpikeDetector do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:current_month) { Date.new(2026, 3, 1) }

  subject(:result) { described_class.new(user: user, date: current_month).call }

  def create_txn(category:, amount:, posted_date:)
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
    context "when current month spend is well above baseline" do
      before do
        # Baseline: Jan + Feb + (default 3 months back from March = Dec, Jan, Feb)
        create_txn(category: "FOOD_AND_DRINK", amount: 100.00, posted_date: Date.new(2025, 12, 15))
        create_txn(category: "FOOD_AND_DRINK", amount: 100.00, posted_date: Date.new(2026, 1, 15))
        create_txn(category: "FOOD_AND_DRINK", amount: 100.00, posted_date: Date.new(2026, 2, 15))
        # Current month: 3x the baseline average
        create_txn(category: "FOOD_AND_DRINK", amount: 300.00, posted_date: Date.new(2026, 3, 15))
      end

      it "detects the spike" do
        spike = result.find { |s| s[:category] == "FOOD_AND_DRINK" }
        expect(spike).to be_present
      end

      it "calculates spike_percentage correctly" do
        # baseline avg = 100, current = 300, ratio = 2.0 = 200%
        spike = result.find { |s| s[:category] == "FOOD_AND_DRINK" }
        expect(spike[:spike_percentage]).to eq(200.0)
      end

      it "includes current_total and baseline_average" do
        spike = result.find { |s| s[:category] == "FOOD_AND_DRINK" }
        expect(spike[:current_total]).to eq(300.00)
        expect(spike[:baseline_average]).to eq(100.00)
      end
    end

    context "when current month spend is within normal range" do
      before do
        create_txn(category: "SHOPPING", amount: 100.00, posted_date: Date.new(2025, 12, 15))
        create_txn(category: "SHOPPING", amount: 100.00, posted_date: Date.new(2026, 1, 15))
        create_txn(category: "SHOPPING", amount: 100.00, posted_date: Date.new(2026, 2, 15))
        # Current month: only 10% above baseline
        create_txn(category: "SHOPPING", amount: 110.00, posted_date: Date.new(2026, 3, 15))
      end

      it "does not flag as a spike" do
        categories = result.map { |s| s[:category] }
        expect(categories).not_to include("SHOPPING")
      end
    end

    context "when a category has no baseline history" do
      before do
        create_txn(category: "NEW_CATEGORY", amount: 500.00, posted_date: Date.new(2026, 3, 15))
      end

      it "does not flag new categories with no baseline" do
        categories = result.map { |s| s[:category] }
        expect(categories).not_to include("NEW_CATEGORY")
      end
    end

    context "with multiple spiking categories" do
      before do
        [ Date.new(2025, 12, 1), Date.new(2026, 1, 1), Date.new(2026, 2, 1) ].each do |d|
          create_txn(category: "TRAVEL", amount: 50.00, posted_date: d)
          create_txn(category: "ENTERTAINMENT", amount: 30.00, posted_date: d)
        end
        create_txn(category: "TRAVEL", amount: 300.00, posted_date: Date.new(2026, 3, 1))
        create_txn(category: "ENTERTAINMENT", amount: 120.00, posted_date: Date.new(2026, 3, 1))
      end

      it "sorts spikes by spike_percentage descending" do
        # TRAVEL: 300 vs 50 avg = 500% spike
        # ENTERTAINMENT: 120 vs 30 avg = 300% spike
        expect(result.first[:category]).to eq("TRAVEL")
        expect(result.second[:category]).to eq("ENTERTAINMENT")
      end
    end

    context "with custom spike_threshold" do
      subject(:result) do
        described_class.new(user: user, date: current_month, spike_threshold: 1.0).call
      end

      before do
        create_txn(category: "GROCERIES", amount: 100.00, posted_date: Date.new(2025, 12, 15))
        create_txn(category: "GROCERIES", amount: 100.00, posted_date: Date.new(2026, 1, 15))
        create_txn(category: "GROCERIES", amount: 100.00, posted_date: Date.new(2026, 2, 15))
        create_txn(category: "GROCERIES", amount: 160.00, posted_date: Date.new(2026, 3, 15))
      end

      it "respects the custom threshold (60% above, threshold 100%)" do
        categories = result.map { |s| s[:category] }
        expect(categories).not_to include("GROCERIES")
      end
    end

    context "when there are no transactions" do
      it "returns an empty array" do
        expect(result).to eq([])
      end
    end
  end
end
