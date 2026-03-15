class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @date = parse_month_param
    @has_accounts = current_user.accounts.exists?
    @categories   = Analysis::CategoryBreakdown.new(user: current_user, date: @date).call
    @merchants    = Analysis::MerchantBreakdown.new(user: current_user, date: @date).call.first(5)
    @spikes       = Analysis::SpendingSpikeDetector.new(user: current_user, date: @date).call.first(1)
    @total_spend  = @categories.sum { |c| c[:total] }
    @recommendation = current_user.recommendations.order(generated_at: :desc).first
    earliest = current_user.transactions.minimum(:posted_date)
    @earliest_month = earliest&.beginning_of_month
  end

  private

  def parse_month_param
    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue ArgumentError, TypeError
    Date.current.beginning_of_month
  end
end
