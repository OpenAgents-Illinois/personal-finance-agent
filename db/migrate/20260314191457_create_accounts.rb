class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plaid_item, null: false, foreign_key: true
      t.string :plaid_account_id
      t.string :name
      t.string :account_type
      t.string :account_subtype
      t.decimal :current_balance
      t.decimal :available_balance
      t.string :iso_currency_code

      t.timestamps
    end
    add_index :accounts, :plaid_account_id, unique: true
  end
end
