class SyncTransactionsJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(plaid_item_id)
    plaid_item = PlaidItem.find(plaid_item_id)
    Plaid::SyncTransactions.new(plaid_item).call
  end
end
