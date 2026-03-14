module Analysis
  class SpendingSpikeDetector
    DEFAULT_BASELINE_MONTHS = 3
    DEFAULT_SPIKE_THRESHOLD = 0.5 # 50% above baseline

    def initialize(user:, date:, baseline_months: DEFAULT_BASELINE_MONTHS, spike_threshold: DEFAULT_SPIKE_THRESHOLD)
      @user = user
      @date = date
      @baseline_months = baseline_months
      @spike_threshold = spike_threshold
    end

    def call
      current = monthly_totals_for(@date)
      baseline = compute_baseline

      current.filter_map do |category, current_total|
        baseline_avg = baseline[category]
        next if baseline_avg.nil? || baseline_avg.zero?

        ratio = (current_total - baseline_avg) / baseline_avg
        next if ratio <= @spike_threshold

        {
          category: category,
          current_total: current_total.round(2),
          baseline_average: baseline_avg.round(2),
          spike_percentage: (ratio * 100).round(1)
        }
      end.sort_by { |s| -s[:spike_percentage] }
    end

    private

    def compute_baseline
      totals_by_month = (1..@baseline_months).map do |i|
        monthly_totals_for(@date - i.months)
      end

      all_categories = totals_by_month.flat_map(&:keys).uniq

      all_categories.each_with_object({}) do |category, averages|
        monthly_values = totals_by_month.map { |m| m[category] || 0 }
        averages[category] = monthly_values.sum.to_f / @baseline_months
      end
    end

    def monthly_totals_for(date)
      @user.transactions
           .posted
           .for_month(date)
           .where("amount > 0")
           .group(:category_primary)
           .sum(:amount)
           .transform_keys { |k| k.presence || "Uncategorized" }
    end
  end
end
