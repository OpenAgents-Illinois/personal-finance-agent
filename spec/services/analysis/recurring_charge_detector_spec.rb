require 'rails_helper'

RSpec.describe Analysis::RecurringChargeDetector do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }

  subject(:result) { described_class.new(user: user).call }

  def create_txn(merchant:, amount:, posted_date:)
    create(:transaction,
      user: user,
      account: account,
      merchant_name: merchant,
      amount: amount,
      posted_date: posted_date,
      pending: false
    )
  end

  describe "#call" do
    context "with monthly transactions" do
      before do
        create_txn(merchant: "Netflix", amount: 15.99, posted_date: Date.new(2026, 1, 1))
        create_txn(merchant: "Netflix", amount: 15.99, posted_date: Date.new(2026, 2, 1))
        create_txn(merchant: "Netflix", amount: 15.99, posted_date: Date.new(2026, 3, 1))
      end

      it "detects a monthly recurring charge" do
        charge = result.find { |r| r[:merchant_name] == "Netflix" }
        expect(charge[:cadence]).to eq("monthly")
      end

      it "sets the correct amount" do
        charge = result.find { |r| r[:merchant_name] == "Netflix" }
        expect(charge[:amount]).to eq(15.99)
      end

      it "sets last_charged_on to the most recent transaction date" do
        charge = result.find { |r| r[:merchant_name] == "Netflix" }
        expect(charge[:last_charged_on]).to eq(Date.new(2026, 3, 1))
      end

      it "persists the recurring charge to the database" do
        expect { result }.to change(RecurringCharge, :count).by(1)
        expect(RecurringCharge.last.merchant_name).to eq("Netflix")
      end
    end

    context "with weekly transactions" do
      before do
        create_txn(merchant: "Gym", amount: 20.00, posted_date: Date.new(2026, 3, 1))
        create_txn(merchant: "Gym", amount: 20.00, posted_date: Date.new(2026, 3, 8))
        create_txn(merchant: "Gym", amount: 20.00, posted_date: Date.new(2026, 3, 15))
      end

      it "detects a weekly recurring charge" do
        charge = result.find { |r| r[:merchant_name] == "Gym" }
        expect(charge[:cadence]).to eq("weekly")
      end
    end

    context "with annual transactions" do
      before do
        create_txn(merchant: "Amazon Prime", amount: 139.00, posted_date: Date.new(2025, 3, 15))
        create_txn(merchant: "Amazon Prime", amount: 139.00, posted_date: Date.new(2026, 3, 15))
      end

      it "detects an annual recurring charge" do
        charge = result.find { |r| r[:merchant_name] == "Amazon Prime" }
        expect(charge[:cadence]).to eq("annual")
      end
    end

    context "with irregular transactions" do
      before do
        create_txn(merchant: "Random Store", amount: 50.00, posted_date: Date.new(2026, 1, 1))
        create_txn(merchant: "Random Store", amount: 50.00, posted_date: Date.new(2026, 2, 20))
      end

      it "does not flag irregular transactions as recurring" do
        merchants = result.map { |r| r[:merchant_name] }
        expect(merchants).not_to include("Random Store")
      end
    end

    context "with only one transaction from a merchant" do
      before { create_txn(merchant: "One-Time Shop", amount: 99.00, posted_date: Date.new(2026, 3, 1)) }

      it "does not flag single transactions as recurring" do
        merchants = result.map { |r| r[:merchant_name] }
        expect(merchants).not_to include("One-Time Shop")
      end
    end

    context "with pending transactions" do
      before do
        create_txn(merchant: "Spotify", amount: 9.99, posted_date: Date.new(2026, 1, 1))
        create(:transaction, user: user, account: account,
          merchant_name: "Spotify", amount: 9.99,
          posted_date: Date.new(2026, 2, 1), pending: true)
      end

      it "excludes pending transactions from detection" do
        merchants = result.map { |r| r[:merchant_name] }
        expect(merchants).not_to include("Spotify")
      end
    end

    context "when a recurring charge already exists" do
      before do
        create_txn(merchant: "Netflix", amount: 15.99, posted_date: Date.new(2026, 1, 1))
        create_txn(merchant: "Netflix", amount: 15.99, posted_date: Date.new(2026, 2, 1))
        create_txn(merchant: "Netflix", amount: 15.99, posted_date: Date.new(2026, 3, 1))
        create(:recurring_charge, user: user, merchant_name: "Netflix",
          amount: 15.99, cadence: "monthly", last_charged_on: Date.new(2026, 2, 1))
      end

      it "updates rather than duplicates the record" do
        expect { result }.not_to change(RecurringCharge, :count)
        expect(RecurringCharge.find_by(merchant_name: "Netflix").last_charged_on)
          .to eq(Date.new(2026, 3, 1))
      end
    end
  end
end
