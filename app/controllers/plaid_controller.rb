class PlaidController < ApplicationController
  before_action :authenticate_user!

  def create_link_token
    response = plaid_client.create_link_token(user_id: current_user.id)
    render json: { link_token: response.link_token }
  rescue Plaid::ApiError => e
    Rails.logger.error("Plaid link token error: #{e.message}")
    render json: { error: "Unable to create link token" }, status: :service_unavailable
  end

  def exchange_public_token
    plaid_item = Plaid::ExchangePublicToken.new(
      user: current_user,
      public_token: params.require(:public_token)
    ).call
    render json: { plaid_item_id: plaid_item.plaid_item_id }, status: :created
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue Plaid::ApiError => e
    Rails.logger.error("Plaid token exchange error: #{e.message}")
    render json: { error: "Unable to exchange token" }, status: :service_unavailable
  end

  private

  def plaid_client
    @plaid_client ||= Integrations::PlaidClient.new
  end
end
