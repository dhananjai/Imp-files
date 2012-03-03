describe User do

  before(:each) do
    @user = User.new
  end

  it "should be invalid without a username" do
    @user.username = nil
    @user.should_not be_valid
    @user.username = 'someusername'
    @user.should be_valid
  end

end
