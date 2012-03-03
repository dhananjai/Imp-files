describe Message do

  before(:each) do
    @message = Message.new(id = 1, sender_id = 1, reciever_id = 2,  message = "cipher")
  end

  it "should be invalid without a message" do
    @message.message = nil
    @message.should_not be_valid
    @message.message = 'some message'
    @message.should be_valid
  end

  it "should be invalid if message limit exceeds 300 words " do
    @message.message = ("cipher " * 301).rstrip
    @message.message.scan(/(\w|-)+/).size > 300    
    @message.should_not be_valid
  end
  
  it "should be valid if message limit is less than 300 words " do
    @message.message = ("cipher " * 301).rstrip
    @message.message.scan(/(\w|-)+/).size < 300    
    @message.should be_valid
  end
  
  it "should be invalid if sender id is nil " do
    @message.sender_id = nil
    @message.should_not be_valid
    @message.sender_id = 1
    @message.should be_valid
  end

  it "should be invalid if reciever id is nil " do
    @message.reciever_id= nil
    @message.should_not be_valid
    @message.reciever_id = 1
    @message.should be_valid
  end

  #not getting on how to write spec ,that name of user whose session is active will not come in drop down list.

end
