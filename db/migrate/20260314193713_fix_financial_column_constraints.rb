class FixFinancialColumnConstraints < ActiveRecord::Migration[8.1]
  def change
    # plaid_items: enforce not-null at DB level
    change_column_null :plaid_items, :plaid_item_id, false
    change_column_null :plaid_items, :access_token_encrypted, false

    # accounts: enforce not-null; add precision/scale to balance columns
    change_column_null :accounts, :plaid_account_id, false
    change_column_null :accounts, :name, false
    change_column :accounts, :current_balance, :decimal, precision: 15, scale: 2
    change_column :accounts, :available_balance, :decimal, precision: 15, scale: 2

    # transactions: enforce not-null on critical fields; fix pending default; add precision to amount
    change_column_null :transactions, :plaid_transaction_id, false
    change_column_null :transactions, :amount, false
    change_column_null :transactions, :name, false
    change_column :transactions, :pending, :boolean, default: false, null: false
    change_column :transactions, :amount, :decimal, precision: 15, scale: 2
  end
end
