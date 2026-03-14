class CreateRecurringCharges < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_charges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :merchant_name, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :cadence, null: false
      t.date :last_charged_on, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
