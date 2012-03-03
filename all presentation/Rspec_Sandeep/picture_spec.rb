require 'spec_helper'
describe Picture do
  before(:each) do
    @piture = Picture.new(:file => File.new(RAILS_ROOT + '/spec/fixtures/104x70.jpg'),:blog_id = 1)
  end
  
  # used to test the accepted images formats like jpeg,gif,jpg,png 
  it "should allow [jpeg,gif,jpg,png,bmp] image formats" do
    # these are the images resides in fixtures folder
    %w(Sample.jpeg Sample.jpg Sample.png Sample.bmp Sample.gif).each { |image|
      picture = Picture.new({:file => File.new(RAILS_ROOT+'/spec/fixtures/'+image)})
      picture.blog_id = 1
      picture.should be_valid
    }
  end  
  
  # used to test the invalid image formats
  it "should not allow [txt, mp3]" do
    # these are the images resides in fixtures folder
    %w(Sample.txt Sample.mp3).each { |image|
      picture = Picture.new({:file => File.new( RAILS_ROOT +'/spec/fixtures/' + image)}) 
      picture.blog_id = 1
      picture.should_not be_valid
      picture.errors.on(:file).should == "is invalid filetype"
    }
  end

  # used to test the accepted images formats like jpeg,gif,jpg,png 
  it "should save the [jpeg,gif,jpg,png,bmp] image formats" do
    # these are the images resides in fixtures folder
    %w(Sample.jpeg Sample.jpg Sample.png Sample.bmp Sample.gif).each { |image|
      picture = Picture.new({:file => File.new(RAILS_ROOT+'/spec/fixtures/'+image)})
      picture.blog_id = 1
      picture.save
    }
  end
end
