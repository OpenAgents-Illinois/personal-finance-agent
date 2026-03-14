require 'rails_helper'

RSpec.describe Analysis::MerchantBreakdown do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, plaid_item: create(:plaid_item, user: user)) }
  let(:date) { Date.new(2026, 3, 1) }

  subject(:result) { described_class.new(user: user, date: date).call }

  def create_txn(merchant:, amount:, posted_date: date)
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
    before do
      create_txn(merchant: "Amazon", amount: 120.00)
      create_txn(merchant: "Amazon", amount: 30.00)
      create_txn(merchant: "Starbucks", amount: 80.00)
      create_txn(merchant: "Uber", amount: 25.00)
    end

    it "returns one entry per merchant" do
      expect(result.map { |r| r[:merchant] }).to match_array(%w[Amazon Starbucks Uber])
    end

    it "sums amounts per merchant" do
      amazon = result.find { |r| r[:merchant] == "Amazon" }
      expect(amazon[:total]).to eq(150.00)
    end

    it "ranks merchants by total spend descending" do
      expect(result.map { |r| r[:merchant] }).to eq(%w[Amazon Starbucks Uber])
    end

    it "assigns sequential ranks starting at 1" do
      expect(result.map { |r| r[:rank] }).to eq([ 1, 2, 3 ])
    end

    it "excludes pending transactions" do
      create(:transaction, user: user, account: account,
        merchant_name: "Netflix", amount: 15.00,
        posted_date: date, pending: true)
      expect(result.map { |r| r[:merchant] }).not_to include("Netflix")
    end

    it "excludes transactions outside the month" do
      create_txn(merchant: "Walmart", amount: 200.00, posted_date: date - 1.month)
      expect(result.map { |r| r[:merchant] }).not_to include("Walmart")
    end

    it "excludes negative amounts" do
      create_txn(merchant: "Amazon", amount: -10.00)
      amazon = result.find { |r| r[:merchant] == "Amazon" }
      expect(amazon[:total]).to eq(150.00)
    end

    context "when merchant_name is nil" do
      before { create_txn(merchant: nil, amount: 50.00) }

      it "groups nil merchants as Unknown" do
        expect(result.map { |r| r[:merchant] }).to include("Unknown")
      end
    end

    context "when there are no transactions" do
      it "returns an empty array" do
        result = described_class.new(user: create(:user), date: date).call
        expect(result).to eq([])
      end
    end
  end
end
