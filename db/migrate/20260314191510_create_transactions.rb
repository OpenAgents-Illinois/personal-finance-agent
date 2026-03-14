class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :plaid_transaction_id
      t.decimal :amount
      t.string :name
      t.string :merchant_name
      t.boolean :pending
      t.date :authorized_date
      t.date :posted_date
      t.string :category_primary
      t.string :category_detailed
      t.jsonb :raw_payload_json

      t.timestamps
    end
    add_index :transactions, :plaid_transaction_id, unique: true
    add_index :transactions, [ :user_id, :posted_date ]
  end
end
