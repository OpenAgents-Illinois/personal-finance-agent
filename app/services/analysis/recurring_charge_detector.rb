module Analysis
  class RecurringChargeDetector
    WEEKLY_RANGE  = (5..9).freeze
    MONTHLY_RANGE = (25..35).freeze
    ANNUAL_RANGE  = (355..375).freeze

    def initialize(user:)
      @user = user
    end

    def call
      detected = detect_recurring_charges
      persist(detected)
      detected
    end

    private

    def detect_recurring_charges
      results = []

      grouped_transactions.each do |key, txns|
        next if txns.size < 2

        merchant, _amount_bucket = key
        dates = txns.map(&:posted_date).sort
        cadence = infer_cadence(dates)
        next unless cadence

        results << {
          merchant_name: merchant,
          amount: txns.last.amount,
          cadence: cadence,
          last_charged_on: dates.last
        }
      end

      results
    end

    def grouped_transactions
      @user.transactions
           .posted
           .where("amount > 0")
           .where.not(merchant_name: [ nil, "" ])
           .order(:posted_date)
           .group_by { |t| [ t.merchant_name, amount_bucket(t.amount) ] }
    end

    def amount_bucket(amount)
      (amount / 5).round * 5
    end

    def infer_cadence(dates)
      gaps = dates.each_cons(2).map { |a, b| (b - a).to_i }
      avg_gap = gaps.sum.to_f / gaps.size

      if WEEKLY_RANGE.cover?(avg_gap)
        "weekly"
      elsif MONTHLY_RANGE.cover?(avg_gap)
        "monthly"
      elsif ANNUAL_RANGE.cover?(avg_gap)
        "annual"
      end
    end

    def persist(detected)
      detected.each do |charge|
        record = RecurringCharge.find_or_initialize_by(
          user: @user,
          merchant_name: charge[:merchant_name]
        )
        record.assign_attributes(
          amount: charge[:amount],
          cadence: charge[:cadence],
          last_charged_on: charge[:last_charged_on],
          active: true
        )
        record.save!
      end
    end
  end
end
