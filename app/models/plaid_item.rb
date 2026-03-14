class PlaidItem < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :destroy

  validates :plaid_item_id, presence: true, uniqueness: true
  validates :access_token_encrypted, presence: true
end
