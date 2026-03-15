class ActionPlanController < ApplicationController
  before_action :authenticate_user!

  def index
    @date             = Date.current.beginning_of_month
    @opportunities    = Planning::SavingsOpportunityEstimator.new(user: current_user, date: @date).call
    @total_savings    = @opportunities.sum { |o| o[:estimated_savings] }
    @recommendations  = current_user.recommendations.order(generated_at: :desc).limit(3)
  end

  def generate
    RecommendationGenerationJob.perform_later(current_user.id)
    redirect_to action_plan_path, notice: "Generating your recommendations — refresh in a few seconds."
  end
end
