class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :plaid_items, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, dependent: :destroy

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
