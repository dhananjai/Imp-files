require 'spec_helper'
describe Likings do
  before(:each) do
    @description = Likings.new(:id => '1',:trigger_response_id => 1,:description => 'some description')
  end
  
  it "should not give error if description is empty" do
    @description.description = ''
    description.should be_valid
  end
  
  it "should save description with some data" do
    @description.save
  end
end
