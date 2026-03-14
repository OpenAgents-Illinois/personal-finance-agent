class Account < ApplicationRecord
  belongs_to :user
  belongs_to :plaid_item
  has_many :transactions, dependent: :destroy

  validates :plaid_account_id, presence: true, uniqueness: true
  validates :name, presence: true
end
