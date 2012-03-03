describe Site do

  before(:each) do
   @site =  Site.new
  end

  it "should be invalid without a sitename" do  # to validate presence of sitename
    @site.sitename = nil
    @site.should_not be_valid
    @site.errors.on(:sitename).should == "can't be blank"
    @site.sitename = 'http://gmail.com'
    @site.should be_valid
  end

  it "should be invalid if site does not start with http:// or https://"  do #to validate format of sitename
    @site.sitename =  'gmail.com'
    @site.should_not be_valid
    @site.errors.on(:sitename).should ==  "http:// is required"
    @site.sitename = 'http://gmail.com' or 'https:paypal.com'
    @site.should be_valid
  end

  it "should be invalid if site is duplicate" do #to validate uniqueness of sitename
    #@site.sitename = 'http://gmail.com'
    @site.should_not be_valid
    @site.errors.on(:sitename).should == "already exist" 
    @site.sitename = 'http://gmail.com'
    @site.should be_valid
  end

end
