module Analysis
  class MerchantBreakdown
    def initialize(user:, date:)
      @user = user
      @date = date
    end

    def call
      transactions
        .group(:merchant_name)
        .sum(:amount)
        .transform_keys { |k| k.presence || "Unknown" }
        .sort_by { |_, v| -v }
        .map.with_index(1) do |(merchant, total), rank|
          {
            rank: rank,
            merchant: merchant,
            total: total.round(2)
          }
        end
    end

    private

    def transactions
      @user.transactions.posted.for_month(@date).where("amount > 0")
    end
  end
end
