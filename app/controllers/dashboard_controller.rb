class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @date = Date.current.beginning_of_month
    @has_accounts = current_user.accounts.exists?
    @categories   = Analysis::CategoryBreakdown.new(user: current_user, date: @date).call
    @merchants    = Analysis::MerchantBreakdown.new(user: current_user, date: @date).call.first(5)
    @spikes       = Analysis::SpendingSpikeDetector.new(user: current_user, date: @date).call.first(1)
    @total_spend  = @categories.sum { |c| c[:total] }
    @recommendation = current_user.recommendations.order(generated_at: :desc).first
  end
end
