class SyncTransactionsJob < ApplicationJob
  queue_as :default

  def perform(plaid_item_id)
    # Implemented in Task 3.4 — Plaid::SyncTransactions service
  end
end
