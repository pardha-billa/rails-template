require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:name)  }

  it { is_expected.to validate_presence_of(:email)  }

  it "Should be invalid with duplicate email account" do
    FactoryGirl.create(:user, email: 'test@emaple.com')
    user = FactoryGirl.build(:user, email: 'test@emaple.com')
    user.valid?
    expect(user.errors[:email]).to include "has already been taken"
  end
end
