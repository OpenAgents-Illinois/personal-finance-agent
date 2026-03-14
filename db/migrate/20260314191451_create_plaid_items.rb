class CreatePlaidItems < ActiveRecord::Migration[8.1]
  def change
    create_table :plaid_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plaid_item_id
      t.string :access_token_encrypted
      t.string :institution_id
      t.string :institution_name
      t.string :last_sync_cursor
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :plaid_items, :plaid_item_id, unique: true
  end
end
