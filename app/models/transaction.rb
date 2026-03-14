class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :account

  validates :plaid_transaction_id, presence: true, uniqueness: true
  validates :amount, presence: true
  validates :name, presence: true

  scope :posted, -> { where(pending: false) }
  scope :for_month, ->(date) { where(posted_date: date.beginning_of_month..date.end_of_month) }
end
