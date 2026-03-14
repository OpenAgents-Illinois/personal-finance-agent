module Analysis
  class CategoryBreakdown
    def initialize(user:, date:)
      @user = user
      @date = date
    end

    def call
      totals = transactions
        .group(:category_primary)
        .sum(:amount)
        .transform_keys { |k| k.presence || "Uncategorized" }
        .sort_by { |_, v| -v }
        .to_h

      grand_total = totals.values.sum

      totals.map do |category, total|
        {
          category: category,
          total: total.round(2),
          percentage: grand_total.zero? ? 0.0 : ((total / grand_total) * 100).round(1)
        }
      end
    end

    private

    def transactions
      @user.transactions.posted.for_month(@date).where("amount > 0")
    end
  end
end
