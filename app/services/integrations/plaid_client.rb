module Integrations
  class PlaidClient
    def initialize
      configuration = Plaid::Configuration.new
      configuration.server_index = server_index
      configuration.api_key["PLAID-CLIENT-ID"] = ENV.fetch("PLAID_CLIENT_ID")
      configuration.api_key["PLAID-SECRET"] = ENV.fetch("PLAID_SECRET")

      api_client = Plaid::ApiClient.new(configuration)
      @client = Plaid::PlaidApi.new(api_client)
    end

    def create_link_token(user_id:)
      request = Plaid::LinkTokenCreateRequest.new(
        user: Plaid::LinkTokenCreateRequestUser.new(client_user_id: user_id.to_s),
        client_name: ENV.fetch("PLAID_APP_NAME", "Personal Finance Agent"),
        products: [ "transactions" ],
        country_codes: [ "US" ],
        language: "en"
      )
      @client.link_token_create(request)
    end

    def exchange_public_token(public_token:)
      request = Plaid::ItemPublicTokenExchangeRequest.new(public_token: public_token)
      @client.item_public_token_exchange(request)
    end

    def sync_transactions(access_token:, cursor: nil)
      request = Plaid::TransactionsSyncRequest.new(
        access_token: access_token,
        cursor: cursor,
        options: Plaid::TransactionsSyncRequestOptions.new(include_personal_finance_category: true)
      )
      @client.transactions_sync(request)
    end

    def get_accounts(access_token:)
      request = Plaid::AccountsGetRequest.new(access_token: access_token)
      @client.accounts_get(request)
    end

    private

    def server_index
      case ENV.fetch("PLAID_ENV", "sandbox")
      when "production" then Plaid::Configuration::Environment["production"]
      when "development" then Plaid::Configuration::Environment["development"]
      else Plaid::Configuration::Environment["sandbox"]
      end
    end
  end
end
