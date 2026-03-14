module Plaid
  class ExchangePublicToken
    def initialize(user:, public_token:)
      @user = user
      @public_token = public_token
    end

    def call
      response = plaid_client.exchange_public_token(public_token: @public_token)

      plaid_item = PlaidItem.find_or_initialize_by(plaid_item_id: response.item_id)
      new_record = plaid_item.new_record?
      plaid_item.assign_attributes(
        user: @user,
        access_token_encrypted: TokenEncryptor.encrypt(response.access_token)
      )
      plaid_item.save!

      SyncTransactionsJob.perform_later(plaid_item.id) if new_record

      plaid_item
    end

    private

    def plaid_client
      @plaid_client ||= Integrations::PlaidClient.new
    end
  end
end
