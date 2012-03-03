require 'spec_helper'
describe Description do
  before(:each) do
    @description = Description.new(:description => 'some description',:blog_id => 1)
  end
  
  it "should not give error if description is empty" do
    @description.description = ''
    description.should be_valid
  end
  
  it "should save description with some data" do
    @description.save
  end
end
