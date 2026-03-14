class RecurringCharge < ApplicationRecord
  belongs_to :user

  validates :merchant_name, presence: true
  validates :amount, presence: true
  validates :cadence, presence: true, inclusion: { in: %w[weekly monthly annual] }
  validates :last_charged_on, presence: true

  scope :active, -> { where(active: true) }
end
