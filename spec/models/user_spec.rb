require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:plaid_items).dependent(:destroy) }
    it { is_expected.to have_many(:accounts).dependent(:destroy) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe "#full_name" do
    it "returns first and last name combined" do
      user = build(:user, first_name: "Jane", last_name: "Doe")
      expect(user.full_name).to eq("Jane Doe")
    end

    it "handles missing last name" do
      user = build(:user, first_name: "Jane", last_name: nil)
      expect(user.full_name).to eq("Jane")
    end
  end
end
