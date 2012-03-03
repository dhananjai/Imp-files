require 'spec_helper'
describe Video do
  before(:each) do
    @video = Video.new(:url =>'http://www.youtube.com',:blog_id => 1)
  end

  it "should not allow invalid URLs" do
    @video.url = 'ww.google.com'
    @video.blog_id = 1
    @video.should_not be_valid
    @video.errors.on(:url).should == "is not in proper format"
    @video.url = 'http://google.com'
    @video.should_not be_valid
  end

  it "should allow youtube URL" do
    @video.url = 'https://www.youtube.com'
    @video.blog_id = 1
    @video.should be_valid
  end

  #Field content should be in format like http:// or https://  
  it "should save the given youtube URL" do
    @video.url = 'https://www.youtube.com'
    @video.blog_id = 1
    @video.save
  end
end
