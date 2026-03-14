class PlaidController < ApplicationController
  before_action :authenticate_user!

  def create_link_token
    response = plaid_client.create_link_token(user_id: current_user.id)
    render json: { link_token: response.link_token }
  rescue Plaid::ApiError => e
    Rails.logger.error("Plaid link token error: #{e.message}")
    render json: { error: "Unable to create link token" }, status: :service_unavailable
  end

  private

  def plaid_client
    @plaid_client ||= Integrations::PlaidClient.new
  end
end
