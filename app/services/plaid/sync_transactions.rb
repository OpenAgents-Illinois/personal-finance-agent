module Plaid
  class SyncTransactions
    def initialize(plaid_item)
      @plaid_item = plaid_item
    end

    def call
      cursor = @plaid_item.last_sync_cursor
      has_more = true

      while has_more
        response = plaid_client.sync_transactions(
          access_token: access_token,
          cursor: cursor
        )

        upsert_accounts(response.accounts) if response.respond_to?(:accounts)
        process_added(response.added)
        process_modified(response.modified)
        process_removed(response.removed)

        cursor = response.next_cursor
        has_more = response.has_more
      end

      @plaid_item.update!(last_sync_cursor: cursor, last_synced_at: Time.current)
    end

    private

    def plaid_client
      @plaid_client ||= Integrations::PlaidClient.new
    end

    def access_token
      @access_token ||= TokenEncryptor.decrypt(@plaid_item.access_token_encrypted)
    end

    def upsert_accounts(accounts)
      accounts.each do |acct|
        account = ::Account.find_or_initialize_by(plaid_account_id: acct.account_id)
        account.assign_attributes(
          user: @plaid_item.user,
          plaid_item: @plaid_item,
          name: acct.name,
          account_type: acct.type,
          account_subtype: acct.subtype,
          current_balance: acct.balances.current,
          available_balance: acct.balances.available,
          iso_currency_code: acct.balances.iso_currency_code
        )
        account.save!
      end
    end

    def process_added(transactions)
      transactions.each do |txn|
        account = ::Account.find_by!(plaid_account_id: txn.account_id)
        record = ::Transaction.find_or_initialize_by(plaid_transaction_id: txn.transaction_id)
        record.assign_attributes(transaction_attributes(txn, account))
        record.save!
      end
    end

    def process_modified(transactions)
      transactions.each do |txn|
        record = ::Transaction.find_by(plaid_transaction_id: txn.transaction_id)
        next unless record

        account = ::Account.find_by!(plaid_account_id: txn.account_id)
        record.update!(transaction_attributes(txn, account))
      end
    end

    def process_removed(transactions)
      ids = transactions.map(&:transaction_id)
      ::Transaction.where(plaid_transaction_id: ids).destroy_all
    end

    def transaction_attributes(txn, account)
      {
        user: @plaid_item.user,
        account: account,
        plaid_transaction_id: txn.transaction_id,
        name: txn.name,
        amount: txn.amount,
        posted_date: txn.date,
        authorized_date: txn.authorized_date,
        pending: txn.pending,
        merchant_name: txn.merchant_name,
        category_primary: txn.respond_to?(:personal_finance_category) ? txn.personal_finance_category&.primary : nil,
        category_detailed: txn.respond_to?(:personal_finance_category) ? txn.personal_finance_category&.detailed : nil,
        raw_payload_json: txn.to_hash
      }
    end
  end
end
