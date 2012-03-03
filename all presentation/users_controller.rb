class UsersController < ApplicationController
  
  before_filter :check_deal
  before_filter :login_required, :except => ['const_page','buyers_review', 'search', 'my_account_tab', 'search_deal_user']
  before_filter :require_user, :only => [:show_access, :user_access, :buying_history, :donation_history, :buying_history_details, :sent_requests, 
:send_invitation, :manage_friends, :manage_followings, :followers, :my_messages, :my_envogue_home,:my_envogue_for_favourite, :my_envogue_for_product_update, :my_envogue_for_donation, :my_envogue_charity_messages,
  :my_envogue_for_bids, :friend_feeds, :add_friend,  :my_favourites, :show_scraps, :charity_messages, :profile_contact_details, :change_password,:orders, :store_credits,:my_invitations]
  
  before_filter :accessing_another_user_profile
  before_filter :check_suspended_user, :only => [:profile_personal_details, :my_favourites, :my_envogue_home, :my_envogue_for_favourite, :my_envogue_for_product_update, :my_envogue_for_donation, :manage_followings, :followers, :my_envogue_for_bids]

  include ActiveMerchant::Billing
  include ItemsHelper  

  require 'spreadsheet/excel'
  require 'active_merchant'  
  require 'money'
  require 'net/http'
  require 'net/https'
  require 'active_support'
 
  # This method is used to dispay the home page for authenticated general user after login.
  def index
    @user_info = UserInfo.find_by_id(params[:id])
  end
  
  # Saurabh 25-07-2009
  # To show message "Page Under Construction"
  def const_page
  end
  


  def my_account_tab
	session[:account_tab] = (session[:account_tab] )? false :true 
	render :text=>"", :layout=>false
  end

  def deny_refund
	@return = OrderReturn.find(params[:id])
	@detail = @return.order_detail
        Notifier::deliver_refund_rejected(@detail.item.seller.email, @detail.item.item_name, @detail.order.user_info.email, @detail.id, request.host_with_port)
	@return.update_attribute("return_status", "rejected")
	@detail.update_attribute("order_status", "refund_rejected")
	redirect_to :back
  end

  def accept_refund
	@return = OrderReturn.find(params[:id])
	@detail = @return.order_detail
        Notifier::deliver_refund_accepted(@detail.item.seller.email, @detail.item.item_name, @detail.order.user_info.email, @detail.id, request.host_with_port)
	@return.update_attribute("return_status", "accepted")
	@detail.update_attribute("order_status", "refund_accepted")
	redirect_to :back
  end

  # Ref:ApplicationController:menu_selector,top_menu_selector(tab)
  def store_credits
	if params[:id] == current_user.id.to_s
		@credits =StoreCredit.paginate(:all, :conditions=>"user_info_id = #{current_user.id}", :page => params[:page], :per_page => 7)
	else
	   	flash[:notice]='Sorry, you are not authorized to view this page.'
		redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
	end
	check_for_active_tab
  end


  def confirm_refund_for_user_specific  ### To make Store Credit User (Not Seller) Specific. ###
	session[:refund_id] = params[:id]
	@return = OrderReturn.find(session[:refund_id])
	@detail = @return.order_detail
	detail_amount = @detail.refund_amount ####### TO-DO ###### Deduct Refund charges
	session[:refund_amount] = detail_amount
	### we have to call paypal/creditcard here  ###	
	@payment_account = PaymentAccount.find_by_user_info_id(current_user.id)
	if @payment_account.account_type == "paypal" 
		store_credit_amount
	elsif @payment_account.account_type == "moneybooker" 
		redirect_to "https://www.moneybookers.com/app/payment.pl?pay_to_email=salil%40cipher-tech.com&transaction_id=#{generate_item_id}&return_url=http%3A%2F%2Flocalhost%3A3000%2Fusers%2Fmoneybooker&cancel_url=http%3A%2F%2Flocalhost%3A3000%2Fusers%2Fmoneybooker&status_url=http%3A%2F%2Flocalhost%3A3000%2Fusers%2Fmoneybooker&language=EN&pay_from_email=#{current_user.email}&country=USA&amount=#{session[:refund_amount]}&currency=USD&detail1_description=Welcome+to+store&detail1_text=Welcome+to+store&ondemand_max_currency=USD&submit_id=Submit&Pay=Pay"
	else
		session[:refund_id] = params[:id]
		@return = OrderReturn.find(session[:refund_id])
		@detail = @return.order_detail
		detail_amount = @detail.refund_amount ####### TO-DO ###### Deduct Refund charges
		session[:refund_amount] = detail_amount

		if @detail.order.user_info.store_credit
			@credit = @detail.order.user_info.store_credit
			amount = @credit.amount + session[:refund_amount]
			@credit.update_attribute("amount", amount)
		else
			@credit = StoreCredit.create(:amount => session[:refund_amount], :user_info_id => @detail.order.buyer_id)
		end
		Notifier::deliver_refund_done(@detail.item.seller.email, @detail.item.item_name, @detail.order.user_info.email, @detail.id, request.host_with_port)
		#@detail.order.update_attribute("amount", @detail.order.amount - detail_amount )   #No need to deduct the refund charges
		@return.update_attribute("return_status", "done" )
		@detail.update_attribute("order_status", "refund_done" )
		session[:refund_id] = nil
		session[:refund_amount] = nil
		flash[:notice] = "Refund is done successfully"
		redirect_to :back
	end
  end
 
  def user_access
	@access = (params[:access][:mark] == "1")? "private":"public"
	@user = User.find_by_user_info_id(current_user.id)
	@user.access = @access
	@user.save
	flash[:notice] = "Access saved successfully"
	redirect_to :back
  end

  def confirm_refund ### To make Store Credit Seller Specific. ###
	if 	params[:refund][:amount].match(/\A[+-]?\d+\Z/) == nil
		flash[:notice] = "please enter numbers only."
	else
		@return = OrderReturn.find(params[:id])
		@detail = @return.order_detail
		detail_amount = params[:refund][:amount].to_f ####### TO-DO ###### Deduct Refund charges

		if @credit = @detail.detail_store_credit
			amount = @credit.amount + detail_amount
			@credit.update_attribute("amount", amount)
		else
			@credit = StoreCredit.create(:amount => detail_amount, :user_info_id => @detail.order.buyer_id, :seller_id =>  @detail.item.seller_id)
		end
		Notifier::deliver_refund_done(@detail.item.seller.email, @detail.item.item_name, @detail.order.user_info.email, @detail.id, request.host_with_port)
		@detail.order.update_attribute("amount", @detail.order.amount - detail_amount )
		@return.update_attribute("return_status", "done" )
		@detail.update_attribute("order_status", "refund_done" )

		flash[:notice] = "Refund is done successfully"
	end
	redirect_to :back
  end


  # Ref: UsersController:confirm_refund_for_user_specific
  def store_credit_amount
    	setup_response = gateway.setup_purchase(session[:refund_amount] * 70,
    	 :ip                => request.remote_ip,
    	 :return_url        => url_for(:controller => 'users', :action => 'confirm', :id => params[:id], :only_path => false),
    	 :cancel_return_url => url_for(:controller => 'users', :action => 'orders', :id => params[:id], :only_path => false)
   	 ) 
    	redirect_to gateway.redirect_url_for(setup_response.token)   
  end   

  # Ref: UsersController:store_credit_amount,confirm,complete
  def gateway
   @gateway ||= PaypalExpressGateway.new(
    :login => 'anubha_1249627299_biz_api1.cipher-tech.com',
    :password => 'AGVVXTM9H73EBTZY',
    :signature => 'AhTlysnz0XvoVv0XBxSV-z1GIKIQA36dvhVCWb0WNclQP8qQy9Gah6QV'
   )
  end

  def confirm
  #redirect_to :controller => 'payment_accounts', :action => 'checkout' unless params[:token]

  details_response = gateway.details_for(params[:token])

  if !details_response.success?
    @message = details_response.message
    redirect_to :controller => 'users', :action => 'error'
    return
  end
 
  @address = details_response.address
 end
  
  def complete
    purchase = gateway.purchase(session[:refund_amount] * 70,
    :ip       => request.remote_ip,
    :payer_id => params[:payer_id],
    :token    => params[:token]
    )
    @transaction_id = purchase.params["transaction_id"]
    if !purchase.success?
      @message = purchase.message
      redirect_to :controller => 'users', :action => 'error', :layout => true 
      return 
    elsif purchase.success?
	@return = OrderReturn.find(session[:refund_id])
	@detail = @return.order_detail
	detail_amount = @detail.refund_amount ####### TO-DO ###### Deduct Refund charges
	session[:refund_amount] = detail_amount

	if @detail.order.user_info.store_credit
		@credit = @detail.order.user_info.store_credit
		amount = @credit.amount + session[:refund_amount]
		@credit.update_attribute("amount", amount)
	else
		@credit = StoreCredit.create(:amount => session[:refund_amount], :user_info_id => @detail.order.buyer_id)
	end
	@transaction = Transaction.create(:transaction_id => @transaction_id, :transaction_type => "store credit", :transaction_type_id => @credit.id, :amount => session[:refund_amount])
	Notifier::deliver_refund_done(@detail.item.seller.email, @detail.item.item_name, @detail.order.user_info.email, @detail.id, request.host_with_port)
	@detail.order.update_attribute("amount", @detail.order.amount - detail_amount )
	@return.update_attribute("return_status", "done" )
	@detail.update_attribute("order_status", "refund_done" )
	session[:refund_id] = nil
	session[:refund_amount] = nil
    end
    flash[:notice] = "Refund is done successfully"
    redirect_to :controller => "users", :action => "orders"
  end

  def moneybooker
     if params[:msid] && params[:transaction_id]
	@transaction_id = params[:transaction_id]	 
	@return = OrderReturn.find(session[:refund_id])
	@detail = @return.order_detail
	detail_amount = @detail.refund_amount ####### TO-DO ###### Deduct Refund charges
	session[:refund_amount] = detail_amount

	if @detail.order.user_info.store_credit
		@credit = @detail.order.user_info.store_credit
		amount = @credit.amount + session[:refund_amount]
		@credit.update_attribute("amount", amount)
	else
		@credit = StoreCredit.create(:amount => session[:refund_amount], :user_info_id => @detail.order.buyer_id)
	end
	@transaction = Transaction.create(:transaction_id => @transaction_id, :transaction_type => "store credit", :transaction_type_id => @credit.id, :amount => session[:refund_amount])
	Notifier::deliver_refund_done(@detail.item.seller.email, @detail.item.item_name, @detail.order.user_info.email, @detail.id, request.host_with_port)
	@detail.order.update_attribute("amount", @detail.order.amount - detail_amount )
	@return.update_attribute("return_status", "done" )
	@detail.update_attribute("order_status", "refund_done" )
	session[:refund_id] = nil
	session[:refund_amount] = nil
	flash[:notice] = "Refund is done successfully"
	redirect_to :controller => "users", :action => "orders"
     else
	flash[:notice] = "Unsuccessful Transaction"
	redirect_to :action => "orders"
     end
  end 
  
  # Saurabh 25-07-2009
  # To show the default access of user "public/private"
  # Ref:ApplicationController:menu_selector,top_menu_selector(tab)
  def show_access
    if params[:id] == current_user.id.to_s
   	@user_info = UserInfo.find_by_id(params[:id])
    else
   	flash[:notice]='Sorry, you are not authorized to view this page.'
	redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
   end
  end

  #To show the Buying activity (Orders) for the User
  # Ref:ApplicationController:menu_selector,top_menu_selector(tab)
  def buying_history
	session[:user_info_id] = current_user.id
	@orders= Order.find(:all, :conditions=>"buyer_id=#{current_user.id}", :order=>'created_at DESC')
	@orders=@orders.paginate(:page => params[:page], :per_page => 7)
	check_for_active_tab
  end

  #To show  the Donation activity (Orders) for the User
  # Ref:ApplicationController:menu_selector,top_menu_selector(tab)
  def donation_history
	session[:user_info_id] =  current_user.id
	@donations = Donation.paginate(:all, :conditions=>"user_info_id=#{current_user.id}", :order=>'created_at DESC', :page => params[:page], :per_page => 7)
	check_for_active_tab
  end


  #To show all the Buying Report (Orders) for the User
  # Ref:ApplicationController:menu_selector
  def buying_report
	#@orders= Order.find(:all, :conditions=>"buyer_id=#{current_user.id}", :order=>'created_at DESC')
	#@orders=@orders.paginate(:page => params[:page], :per_page => 7)
	session[:user_info_id] = current_user.id.to_i
	@year = (params[:date] && params[:date][:year])? params[:date][:year] : Date.today.year.to_s 
	@value = ( params[:user] &&  params[:user][:value])?  params[:user][:value] : "order_number"
	@bar_graph = ofc2(500,200,"users/line_chart/#{@value}?year=#{@year}&& ")
  end


  # Ref:UsersController:buying_report
  def line_chart
   @value = params[:id]
   @year = params[:year]
   title = OFC2::Title.new( :text => "" ,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
   number_of_order = []
   spend_money = []
   for i in months_array
	order_id = []
	@orders = Order.find(:all, :select=>'amount', :conditions=>"buyer_id=#{current_user.id} and date_format(created_at, '%b-%Y')='#{i}-#{@year}'")
	money = 0.0
	number = (@orders.length!=0)? @orders.length : 0
	for order in @orders
     		money += order.amount
        end 
	number_of_order << number
	spend_money << money
   end
   if @value == "order_number"
	line_dot = OFC2::Bar.new(:text=>"", :colour=>"#87421F", :values => number_of_order)
	@max = maxInArray(number_of_order)
	@min = minInArray(number_of_order)
	title_value = "Number of Orders"
   else
	title_value = "Sales in US $"
	line_dot = OFC2::Bar.new(:text=>"", :colour=>"#87421F", :values => spend_money)
	@max = maxInArray(spend_money)
	@min = minInArray(spend_money)
   end


   if @max.to_i == 0 && @min.to_i == 0
    y = OFC2::YAxis.new( :min => 0, :max => 21, :steps=>7)
   else
    y = OFC2::YAxis.new( :min => @min, :max => @max, :steps=>(@max-@min)/5) 
   end
   chart = OFC2::Graph.new
   chart.title= title
   chart << line_dot
   x = OFC2::XAxis.new
   chart.y_axis= y
   y_legend=OFC2::YLegend.new( :text => "#{title_value}" ,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
   chart.y_legend=y_legend
   x_axis_label=[]
	x_labels = OFC2::XAxisLabels.new
	for month in months_array
		x_axis_label << OFC2::XAxisLabel.new( :text=> month,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
	end

   x_labels.labels= x_axis_label
   x.labels= x_labels
   x_legend=OFC2::XLegend.new( :text => "Months" ,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
   chart.x_legend=x_legend
   chart.x_axis= x
   chart.bg_colour= '#F0F6FF'
   render :text => chart.render
  end

  #To show all the Selling Report (Orders) for the User
  # Ref:ApplicationController:menu_selector
  def selling_report
	@year = (params[:date] && params[:date][:year])? params[:date][:year] : Date.today.year.to_s 
	@value = ( params[:user] &&  params[:user][:value])?  params[:user][:value] : "order_number"
	@bar_graph = ofc2(500,200,"users/line_chart_selling/#{@value}?year=#{@year}&& ")
  end

  # Ref:UsersController:selling_report
  def line_chart_selling
   @value = params[:id]
   @year = params[:year]
   title = OFC2::Title.new( :text => "" ,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
   number_of_order = []
   spend_money = []


   for i in months_array
	order_id = []
	@orders= OrderDetail.find_by_sql("select * from order_details o where o.item_id in (select id From items i where i.seller_id= #{current_user.id}) and date_format(o.created_at, '%b-%Y')='#{i}-#{@year}'")

	money = 0.0
	number = []
	for order in @orders
		money += order.detail_amount
		number << order.order_id if !number.include?(order.order_id)
	end
	number_of_order << number.length
	spend_money << money
   end

   if @value == "order_number"
	line_dot = OFC2::Bar.new(:text=>"", :colour=>"#87421F", :values => number_of_order)
	@max = maxInArray(number_of_order)
	@min = minInArray(number_of_order)
	title_value = "Number of Orders"
   else
	title_value = "Earn in US $"
	line_dot = OFC2::Bar.new(:text=>"", :colour=>"#87421F", :values => spend_money)
	@max = maxInArray(spend_money)
	@min = minInArray(spend_money)
   end


   if @max.to_i == 0 && @min.to_i == 0
    y = OFC2::YAxis.new( :min => 0, :max => 21, :steps=>7)
   else
    y = OFC2::YAxis.new( :min => @min, :max => @max, :steps=>(@max-@min)/5) 
   end
   chart = OFC2::Graph.new
   chart.title= title
   chart << line_dot
   x = OFC2::XAxis.new
   chart.y_axis= y
   y_legend=OFC2::YLegend.new( :text => "#{title_value}" ,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
   chart.y_legend=y_legend
   x_axis_label=[]
	x_labels = OFC2::XAxisLabels.new
	for month in months_array
		x_axis_label << OFC2::XAxisLabel.new( :text=> month,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
	end

   x_labels.labels= x_axis_label
   x.labels= x_labels
   x_legend=OFC2::XLegend.new( :text => "Months" ,  :style => "{font-size: 14px; color: #b50F0F; text-align: center;}")
   chart.x_legend=x_legend
   chart.x_axis= x
   chart.bg_colour= '#F0F6FF'
   render :text => chart.render
  end



  #To show all the Selling activity (Orders) for the User
  def orders
    session[:user_info_id] = current_user.id
    @orders= OrderDetail.find_by_sql("select * from order_details o where o.item_id in (select id From items i where i.seller_id= #{current_user.id}) order by  o.created_at DESC")
    @deals=Deal.find_by_sql(["select * From deals i where i.seller_id= #{current_user.id}"])
    @deals=@deals.paginate(:page => params[:page_deal], :per_page => 10)
    @orders=@orders.paginate(:page => params[:page], :per_page =>10 )
  end

  # Method for deal details according to deals 
  def deal_order_details
      session[:user_info_id] = current_user.id
      @orders = []
      @deal_applicant= DealApplicant.find_by_sql("select * from deal_applicants o where o.deal_id = #{params[:id]} AND o.paid = true order by  o.created_at DESC")
      @deal_applicant.each do|deal_app|
       order = DealOrder.find(:first, :conditions=>"deal_id ='#{deal_app.deal_id}' && buyer_id = '#{deal_app.buyer_id}'")
        @orders << order if order
      end if @deal_applicant
      @orders_page=@orders.paginate(:page => params[:page], :per_page => 10)
      check_for_active_tab
  end
  
   # ---------------------------------------- Export to xls Section ---------------------------------------
   #Ref: UsersController:export_to_excel_to_deal_order
  def export_to_excel(&block)
    Tempfile.open("xls") do |tempfile|
      @workbook = Spreadsheet::Excel.new(tempfile)
      worksheet = @workbook.add_worksheet
      @format_text = @workbook.add_format(:bold => false, :color => 'black')
      @format_header = @workbook.add_format(:color => 'blue', :size => 14, :bold => true)
      @bold = @workbook.add_format(:bold => true)
      worksheet.format_column(0, 30, @format_text)
      worksheet.format_column(1, 30, @format_text)
      worksheet.format_column(2, 25, @format_text)
      worksheet.format_column(3, 25, @format_text)
      worksheet.format_column(4, 15, @format_text)
      worksheet.format_column(5, 25, @format_text)
      worksheet.format_column(6, 20, @format_text)
      worksheet.format_column(7, 20, @format_text)
      worksheet.format_column(8, 25, @format_text)
      filename = 'report.xls'
      if block_given?
        yield(worksheet, filename)
        @workbook.close
        send_file tempfile.path, :filename => filename, :type =>'application/vnd.ms-excel'
      end
    end
  end

  # Method to export a deal order
  # Deepali Thaokar # 17/09/2011
  def export_to_excel_to_deal_order
     #deal_order_details
      deal_applicant = DealApplicant.find(:all,:conditions=>["deal_id='#{params[:id]}'"])
      deal = Deal.find_by_id(params[:id])
     export_to_excel do |worksheet, filename|
      worksheet.write(0, 0, 'Deal Orders', @format_header)
      worksheet.write(1, 0, 'Order ID', @bold)
      worksheet.write(1, 1, 'Deal Applicant Name', @bold)
      worksheet.write(1, 2, 'Deal Apply Date', @bold)
      worksheet.write(1, 3, 'Payment Method', @bold)
      worksheet.write(1, 4, 'Purchase Status', @bold)
      worksheet.write(1, 5, 'Amount Paid($)', @bold)
      worksheet.write(1, 6, 'Coupon Code', @bold)
      worksheet.write(1, 7, 'Deal Quantity', @bold)
      worksheet.write(1, 8, 'Size & Color', @bold)
      #worksheet.write ########
       i = 2
       deal_applicant.each do |dl|
        deal_order = DealOrder.find(:first, :conditions=>"deal_id='#{dl.deal_id}' AND buyer_id='#{dl.buyer_id}'")
        if dl.paid && deal_order
        buyer_info = User.find_by_user_info_id(dl.buyer_id)
        filename.replace deal.deal_name+'.xls'
        name = (buyer_info && buyer_info.first_name ? buyer_info.first_name.capitalize : "") +" "+ (buyer_info && buyer_info.last_name ? buyer_info.last_name.capitalize : "")
        status = dl.paid ? "Paid" : "Unpaid"
        code = deal_order && deal_order.deal_order_code ? deal_order.deal_order_code : ""
        amount = (dl.quantity*deal.sale_price).to_f if dl.paid
        sizecoloroption = DealColorSizeOption.find(:first, :conditions =>["deal_applicant_id = #{dl.id}"]) if dl
        dealsizecolor= sizecoloroption.size+" / "+sizecoloroption.color if sizecoloroption
        sizecolor = sizecoloroption ? dealsizecolor : "not applicable"
        worksheet.write(i, 0, deal_order.deal_order_number, @format_text)
        worksheet.write(i, 1, name, @format_text)
        worksheet.write(i, 2, dl.deal_apply_date.strftime("%m/%d/%y"), @format_text)
        worksheet.write(i, 3, deal_order.payment_mode, @format_text)
        worksheet.write(i, 4, status, @format_text)
        worksheet.write(i, 5, amount.to_s, @format_text)
        worksheet.write(i, 6, code, @format_text)
        worksheet.write(i, 7, dl.quantity, @format_text)
        worksheet.write(i, 8, sizecolor, @format_text)
       i = i+1
        end
      end
     end
  end
# ---------------------------------------- Export to xls Section ---------------------------------------#

  #To show all the Buying activity for the User for particular (Order)
  # Ref:ApplicationController:menu_selector; Notifire:refund_rejected,refund_accepted,refund_done
  def buying_history_details
	@order_id = Order.find(params[:id])
	session[:user_info_id] = current_user.id
	if @order_id.buyer_id == current_user.id
		@order_details= OrderDetail.find(:all, :conditions=>"order_id=#{params[:id]}")
		@order_details=@order_details.paginate(:page => params[:page], :per_page => 7)
	else
	   	flash[:notice]='Sorry, you are not authorized to view this page.'
		redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
	end
  end

  # Ref: UsersController:change_order_status; ApplicationController:menu_selector
  def order_details
   @order_detail_id = OrderDetail.find(params[:id])
   session[:user_info_id] = current_user.id
   if @order_detail_id.item.seller_id == current_user.id
	   @delivery_trackings= DeliveryTracking.find(:all, :conditions=>"order_detail_id=#{params[:id]}", :order=>'delivery_status_date DESC')
	   @delivery_trackings=@delivery_trackings.paginate(:page => params[:page], :per_page => 7)
   else
   	flash[:notice]='Sorry, you are not authorized to view this page.'
	redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
   end
  end

  # Ref:ApplicationController:menu_selector
  def change_order_status
   @delivery_trackings= DeliveryTracking.find(:all, :conditions=>"order_detail_id=#{params[:id]}", :order=>'delivery_status_date DESC')
   @delivery_trackings=@delivery_trackings.paginate(:page => params[:page], :per_page => 7)
   @delivery_tracking = DeliveryTracking.new(params[:delivery_tracking])
   if @delivery_tracking.valid? 
      @delivery_tracking.save
   end
    render :action => "order_details", :id => params[:id]
  end 

  # Method to search a friend with name, emailid and keyword for blog
  # Updated to add a condition for deal user also # Deepali Thaokar
  # Ref:UsersController:send_invitation
  def search_friends
    @search_users = []
    @search_friends = []
    session[:user_info_id] =  (current_user)? current_user.id : session[:user_info_id]
    params[:page]= "1"  unless params[:page]
    if params[:search_friends] && !params[:search_friends].blank?
      user_id = []
      query = (current_user)? " && user_info_id != #{current_user.id}"  :  " "
      params[:search_friends] = (!params[:search_friends].blank? && params[:search_friends] != "Search People")? params[:search_friends] : "%"
      for param in params[:search_friends].split(" ")
        if current_user.account_type == "admin"
          login_user = Login.find(:all, :select => 'user_info_id', :conditions=>["(username like :text)"+query,{:text=>"%#{params[:search_friends]}%"}])
          login_user_id = login_user.collect {|v|  v.user_info_id}
        else
          user = User.find(:all, :select => 'id', :conditions=>["(first_name like :text or last_name like :text )"+query,{:text=>"%#{param}%"}])
          user_id = user.collect {|v|  v.id} if user_id == []
          user_id = user_id & user.collect {|v|  v.id}
        end
      end
      @search_users = User.find(:all,:conditions=>["id in (#{user_id.join(',')})"]) if user_id != []
      for user in @search_users
        @search_friends << user if user.user_info.is_active? && (user.user_info.account_type == "user" || user.user_info.account_type == "deal")
      end
      if current_user.account_type == "admin"
        @search_logins = User.find(:all,:conditions=>["user_info_id in (#{login_user_id.join(',')})"]) if login_user_id != []
        for user in @search_users
          @search_friends << user if user.user_info.is_active? && (user.user_info.account_type == "user" || user.user_info.account_type == "deal")
        end
      end

    elsif params[:search_email] && !params[:search_email].blank?
      @search_users = UserInfo.search_by_email params[:search_email][:text]
      for user_info in @search_users
        @search_friends << user_info.user if user_info.is_active? && (user_info.account_type == "user" || user_info.account_type == "deal") && !@search_friends.include?(user_info.user) && user_info.id.to_i != current_user.id.to_i
      end
    elsif params[:search_blog] && !params[:search_blog].blank?
      @search_blogs = Blog.search params[:search_blog][:text]
      for blog in @search_blogs
        @search_friends << blog.user_info.user if blog.user_info.is_active? && (blog.user_info.account_type == "user" || blog.user_info.account_type == "deal") && !@search_friends.include?(blog.user_info.user) && blog.user_info.id.to_i != current_user.id.to_i
      end
    end
    advance_search_friends  if params[:advance_search_friends] && @search_friends != []
    @search_friends = @search_friends.paginate(:page => params[:page], :per_page => 3)
    if current_user.account_type == "admin"
      @user_info_users = []
      if !@search_logins.blank?
        @search_logins.each do |user|
          @user_info_users << user.user_info
        end
      end
      @user_info_users = @user_info_users.paginate(:page => params[:page], :per_page => 5)
      #redirect_to  :controller => :admin , :action => :manage_users_signup
      render :template => "admin/manage_users_signup"
    end
    session[:top_menu] = "find_people"
    session[:sub_menu] = "find_people"
    session[:access_tab] = "user"
  end
  


  def search
    @charities = Charity.search params[:search]
    if current_user.account_type == "admin"
          @user_info_charities = []
          @charities.each do |charity|            
            @user_info_charities << charity             
          end
          @user_info_charities = @user_info_charities.paginate(:page => params[:page], :per_page => 5)
          #redirect_to  :controller => :admin , :action => :manage_users_signup
          render :template => "admin/manage_charities_signup"
    end      
  end

  
  def search_deal_user
    @deal_users = User.search_deal_user(params[:search_deal_user])
    if current_user.account_type == "admin"
          @deal_info_users = []
          @deal_users.each do |deal|            
            @deal_info_users << deal             
          end
          @deal_info_users = @deal_info_users.paginate(:page => params[:page], :per_page => 5)
          #redirect_to  :controller => :admin , :action => :manage_users_signup
          render :template => "admin/manage_deals_signup"
    end      
  end

  # Ref:UsersController:search_friends
  def advance_search_friends
    city_cond, sex_cond, interest_cond, age_cond = true, true, true, true
    city_arr, sex_arr, interest_arr, interest_arr_id, age_arr = [], [], [], [], []
    params[:page]= "1"  unless params[:page]
    if params[:city] && !params[:city].blank?
      @user_city = UserInfo.find(:all,  :conditions=>["(city like :text)", {:text=>"%#{params[:city]}%"}])
      city_arr = User.find(:all, :select=>'id', :conditions =>"user_info_id in (#{@user_city.collect {|v|  v.id}.join(',')})" ).collect {|v|  v.id} if @user_city != []
      city_cond = false
    end
    if  params[:sex] && !params[:sex].blank? && ['Male', 'Female'].include?(params[:sex])
      sex_arr = User.find(:all, :select=>'id', :conditions =>"sex = '#{params[:sex]}'").collect {|v|  v.id}
      sex_cond = false
    end
    if params[:interest] && !params[:interest].blank?
      for param in params[:interest].split(" ")
        user = User.find(:all, :select => 'id', :conditions=>["(interests like :text ) ",{:text=>"%#{param}%"}])
        interest_arr_id = user.collect {|v|  v.id} if interest_arr_id == []
        interest_arr_id = interest_arr_id & user.collect {|v|  v.id}
      end
      @interest_friends = User.find(:all, :select=>'id', :conditions=>["id in (#{interest_arr_id.join(',')})"]) if interest_arr_id != []
      interest_arr = @interest_friends.collect {|v|  v.id}   if @interest_friends
      interest_cond = false
    end
    @advance = @search_friends
    @search_friends = []
    for friend in @advance
      @search_friends << friend if (city_cond || (!city_cond && city_arr.include?(friend.id))) && (sex_cond || (!sex_cond && sex_arr.include?(friend.id)))  && (interest_cond || (!interest_cond && interest_arr.include?(friend.id)))
    end
    #@search_friends = @search_friends.paginate(:page => params[:page], :per_page => 3)
  end


  # GET /users/1
  # GET /users/1.xml
  def show
   	flash[:notice]='Sorry, you are not authorized to view this page.'
    redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new
    @userinfo= UserInfo.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # This method is used to edit the user personal details.
  def edit
    if  (!current_user.is_admin? && (params[:id] == current_user.id.to_s)) || (params[:id] && current_user.is_admin?)
        session[:user_info_id] = params[:id] if current_user.is_admin? && !(params[:id] == current_user.id.to_s) 
	@user_info = UserInfo.find(params[:id])
        @user = @user_info.user
	#session[:user_info_id] = current_user.id
    else
   	flash[:notice]='Sorry, you are not authorized to view this page.'
	redirect_to :controller => "users", :action => 'profile_personal_details', :id => current_user.id
    end
  end
   
 

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(@user) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

   # This method is used to update the user personal details.
  def update
    @user = User.find(params[:id])
    @user_info = @user.user_info
    @user_info.attributes=params[:user_info]    
    @user.attributes=params[:user]    
    # (@user_info.valid? & @user.valid?) this is used for retrieving error message for both user and user_info
    if (@user_info.valid? & @user.valid?) &&  @user_info.save  && @user.save
      flash[:notice] = "Personal details have been updated successfully."
      redirect_to :action => "profile_personal_details", :id => @user_info.id 
    else
      return(render (:action => 'edit', :id =>@user_info.id))
    end	
  end

  # This method is used to find all received requests by a registered user.
  # Ref:ApplicationController:menu_selector,top_menu_selector(tab),login_required; Notifire:follower_info
  def received_requests
	session[:user_info_id] =  current_user.id
	if request.post?
		if params[:user_ids]
			query=(params[:commit] == "Accept")? "Accepted" : "Rejected"
			FollowerUser.update_all("status ='#{query}'", "id in (#{params[:user_ids].join(',')})") 
			for id in params[:user_ids]
				user_info_id=FollowerUser.find(id).user_info_id
				follower_id=FollowerUser.find(id).follower_id
			        (query=="Accepted")? Notifier::deliver_accept_request(find_user_info(follower_id).email, find_user_info(follower_id).login.username, find_user_info(user_info_id).login.username) : Notifier::deliver_reject_request(find_user_info(follower_id).email, find_user_info(follower_id).login.username, find_user_info(user_info_id).login.username)
			end
			flash[:notice]="Request(s) successfully "+query
		else
			flash[:notice]="please select the checkbox."
		end
	end
	@requests=FollowerUser.requests(current_user.id, true).paginate(:page=>params[:page], :per_page=>7)
        check_for_active_tab
  end


  # This method is used to find all sent requests by a registered user.
  # Ref:ApplicationController:menu_selector
  def sent_requests
	session[:user_info_id] =  current_user.id
	if request.post?
		if params[:user_ids]
			Friend.update_all("request_status ='Pending'", "id in (#{params[:user_ids].join(',')})") 
			for id in params[:user_ids]
				user_info_id=Friend.find(id).user_friend_id
			        Notifier::deliver_sent_request(find_user_info(user_info_id).email)
			end
			flash[:notice]="Requests sent successfully "
		else
			flash[:notice]="please select the checkbox."
		end
	end
	@requests=Friend.requests(current_user.id, false).paginate(:page=>params[:page], :per_page=>7)
        check_for_active_tab
  end

  # This method is used to send invitation for a guest.
  # Ref:ApplicationController:menu_selector
  def send_invitation
	if request.post?
		if  params[:friend][:email].blank?
			flash[:notice] = "you have not entered email address."
			redirect_to :controller => "users", :action => "search_friends", :send_invitation => "true" if params[:search] == "advanced_search"
		elsif params[:friend][:email].to_s.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i) == nil 
			flash[:notice] = "please entered valid email address."
			redirect_to :controller => "users", :action => "search_friends", :send_invitation => "true" if params[:search] == "advanced_search"
		else
			@user_info = UserInfo.find(:first, :conditions => "email = '#{params[:friend][:email]}' || alternate_email = '#{params[:friend][:email]}'")			
			if !@user_info.blank? && !(@user_info.account_type == "visitor")   
				flash[:notice] = "User already exists in sevenzens."
				redirect_to :controller => "users", :action => "search_friends", :send_invitation => "true" if params[:search] == "advanced_search"			
			else
				Notifier::deliver_send_invitation(params[:friend][:email], params[:friend][:comment],current_user, request.host_with_port)
				flash[:notice] = "Invitation has been sent successfully."
				redirect_to :controller => "users", :action => "search_friends", :send_invitation => "true" if params[:search] == "advanced_search"
			end
		end
	end
  end


  # This method is used to edit the user contact details.
  # Ref:UsersController:update_contact_details; ApplicationController:menu_selector
  def edit_contact_details
    @country = Country.all
    if  (!current_user.is_admin? && (params[:id] == current_user.id.to_s)) || (params[:id] && current_user.is_admin?)
         session[:user_info_id] = params[:id] if current_user.is_admin? && !(params[:id] == current_user.id.to_s) 
   	 @user_info = UserInfo.find(params[:id])
         @country = Country.all
         @state = State.find(:all, :conditions=>["country_id = ? and state_name is not null",@user_info.country], :group=>'state_name', :order=>'state_name')
  	 @cities =  City.find(:all, :conditions=>["country_id = ? and state_id = ? and city_name is not null", @user_info.country , @user_info.state],:group=>'city_name', :order=>'city_name')
   	 @contact_type = @user_info.account_type  #This is used for the Admin left menu
	 #session[:user_info_id] = current_user.id 
    else
   	flash[:notice]='Sorry, you are not authorized to view this page.'
	redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
    end
  end

   # This method is used to update the user personal details.
  def update_contact_details
    @user_info = UserInfo.find(params[:id])
    @country = Country.all
    @state = State.find(:all, :conditions=>["country_id = ? and state_name is not null ",@user_info.country], :group=>'state_name', :order=>'state_name')
    @cities =  City.find(:all, :conditions=>["country_id = ? and state_id = ? and city_name is not null", @user_info.country , @user_info.state],:group=>'city_name', :order=>'city_name')
    if @user_info.update_attributes(params[:user_info])
        flash[:notice] = "#{@user_info.account_type.capitalize} updated successfully."
      redirect_to :action => "profile_contact_details", :id => @user_info.id 
    else
    @state = State.find(:all, :conditions=>["country_id = ?",params[:user_info][:country]], :group=>'state_name', :order=>'state_name')
    @cities =  City.find(:all, :conditions=>["country_id = ? and state_id = ?", params[:user_info][:country] , params[:user_info][:state]],:group=>'city_name', :order=>'city_name')

      return(render (:action => 'edit_contact_details', :id =>@user_info.id))
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    #@user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end  
  

  # This method is used to provide personal information of the sign in user.
  # Ref:PicturesController:profile_image; LoginsController:about_us,login,sign_up,sign_up_new,user; UsersController:edit,update,profile_contact_detail,send_msg,my_favourites,follow;ApplicationController:top_menu_selector(tab),menu_selector;AdminController:admin_profile
  def profile_personal_details
    if current_user && current_user.is_charity?
      flash[:notice]='Sorry, you are not authorized to view this page.'
      redirect_to :controller => "charities", :action => 'index', :id => current_user.id
    else
            @account= UserInfo.find(params[:id])
	    @user_info = UserInfo.find(params[:id])  
	    @user = @user_info.user
	    session[:user_info_id]= @user_info.id 
    end
    check_for_active_tab
  end 

  # This method is used to provide contact information of the sign in user.
  # Ref: ItemsController:edit; LoginsController:sign_up_non_user; UsersController:store_credits,show_access,buying_history_details,order_details,show,edit_contact_details,update_contact_details,change_password; AlbumsController:edit; ApplicationController:top_menu_selector(tab),menu_selector; PaymentAccountsController:show,payment_details,edit; CategoriesController:show
  def profile_contact_details
    if  (params[:id] == current_user.id.to_s) || current_user.is_admin?
	    @user_info = UserInfo.find(params[:id])
            if !@user_info.country.nil? 
              @countryname = Country.find_by_country_code(@user_info.country)
              @country = (!@countryname.nil?)? @countryname.country_name : "" 
            end
            if !@user_info.state.nil?
              @statename = State.find_by_country_id_and_state_id(@user_info.country,@user_info.state)
              @state = (!@statename.nil?)? @statename.state_name : ""
            end
	    @contact_type = @user_info.account_type  #This is used for the Admin left menu
      session[:user_info_id]= params[:id].to_i
    else
   	flash[:notice]='Sorry, you are not authorized to view this page.'
	redirect_to :controller => "users", :action => 'profile_personal_details', :id => current_user.id
    end
    check_for_active_tab
  end

  # This method is used to change the old password.
  # Ref: ApplicationController:top_menu_selector(tab),menu_selector
  def change_password
   session[:user_info_id] = current_user.id
   if  params[:id] == current_user.id.to_s
    if params[:old]
      @login= Login.authenticate(current_user.login.username, params[:old][:password])
      @login.attributes=params[:login] if @login
      if @login && @login.save
	        flash[:password_notice]="Congratulation ! Password has been changed."
		redirect_to :action=>"change_password"
      else
		flash[:password_message]="Please enter correct old password." if @login.nil?
  		render :action=>"change_password"
      end
    end
   else
   	flash[:notice]='Sorry, you are not authorized to view this page.'
	redirect_to :controller => "users", :action => 'profile_contact_details', :id => current_user.id
   end 
   check_for_active_tab
  end

  # This method is used to display all friends of the log in user.
  def manage_friends
	@friends = Friend.paginate(:all, :conditions=>["(user_info_id=#{current_user.id} or user_friend_id=#{current_user.id} )&& request_status='Accepted' "], :page => params[:page], :per_page => 15)
  end

  # Ref: UsersController:remove_following;ApplicationController:top_menu_selector(tab),menu_selector,require_user
  def manage_followings

	session[:user_info_id] =  params[:id]? params[:id].to_i : current_user.id
        
	@user_info = UserInfo.find_by_id(session[:user_info_id])
	@access = @user_info.user.access
	@friends = FollowerUser.paginate(:all, :conditions=>["follower_id=#{session[:user_info_id]} && status='Accepted' "], :page => params[:page], :per_page => 18)
	check_for_active_tab
  end

  # Ref: UsersController:remove_followers;ApplicationController:top_menu_selector(tab),menu_selector,require_user
  def followers
	session[:user_info_id] =  params[:id]? params[:id].to_i : current_user.id
	@user_info = UserInfo.find_by_id(session[:user_info_id])
	@access = @user_info.user.access
	@friends = FollowerUser.paginate(:all, :conditions=>["user_info_id=#{session[:user_info_id]} && status='Accepted' "], :page => params[:page], :per_page => 18)
	check_for_active_tab
  end


# Abhijeet Ghude 2010/11/04 
# My_invitations method for bita invitation implementation 
# Ref: ApplicationController:menu_selector
  def my_invitations 
	session[:user_info_id] = current_user.id.to_i
  end


# Abhijeet Ghude 2010/10/28
# sending reply notification msg mail to personal email address
# Ref:ApplicationController:top_menu_selector(tab),menu_selector; Notifire:mail_for_reply
  def my_messages
  session[:user_info_id] = current_user.id.to_i
        @current_user_name = User.find_by_user_info_id(current_user.id)
	@messages = Message.received_messages(current_user.id).paginate(:page => params[:page], :per_page => 12)
	if request.post?
  		@message=Message.new(params[:message])
		render :update do |page|
			if @message.save
			         @receiver= User.find_by_user_info_id(@message.receiver_id).first_name
				 @receiver_email= UserInfo.find_by_id(@message.receiver_id).email
				 flash="Message has been sent successfully."
				 Notifier::deliver_mail_for_reply(@message,@current_user_name,@receiver,@receiver_email,request.host_with_port)
                                 page.replace_html "notice_#{params[:message_id]}", "<span class='flash'>#{flash}</span>" #"<span style='color:red'>#{flash}</span>"
				 page.hide "reply_#{params[:message_id]}"
				 page.hide "replytext_#{params[:message_id]}"
			else
				 flash=(!@message.message.match("<").nil?) ? "Please don't enter html code." : "Reply can't be blank."
				 page.replace_html "notice_#{params[:message_id]}", "<span style='color:red;padding-left:80px'>#{flash}</span>"
				 page.show "reply_#{params[:message_id]}"
				 page.show "replytext_#{params[:message_id]}"
			end
  		 end
	end
	check_for_active_tab
  end
# Abhijeet Ghude 2010/10/28
# sending notification msg mail to personal email address
# Ref:ApplicationController:top_menu_selector(tab),menu_selector,login_required; Notifire:mail_to_favorited,donors_mass_message_for_user
  def charity_messages
    	@msg = CharitiesMassMessage.find(:all, :select=>'mass_message_id', :conditions=>["user_info_id = ? ", current_user.id])
	ids=[]
	@msg.collect{|m| ids << m.mass_message_id } unless @msg.blank? 
        @charity_messages = (ids.blank?)? [] : MassMessage.paginate(:all, :conditions=>["id in (?) and message_type !='envogue_favourited'", ids], :page => params[:page], :per_page => 12, :order=>'created_at DESC')
        check_for_active_tab
  end

  #31-05-2010
  # this method will generate the list of messages sent by the user
  # Ref:ApplicationController:top_menu_selector(tab),menu_selector
  def sent_messages
    @sent_messages = Message.sent_messages(current_user.id).paginate(:page => params[:page], :per_page => 12)
    check_for_active_tab 
  end

  # This method is used to remove message.
  def remove_message
    @message=Message.find(params[:id])    
    if @message.message_author_id == current_user.id
      @message.is_deleted_by_sender = true
    else
      @message.is_deleted_by_receiver = true
    end
    if (@message.is_deleted_by_sender == true) &&  (@message.is_deleted_by_receiver == true)
      @message.destroy
    else
      @message.save
    end
    flash[:notice]="Message deleted successfully."
    redirect_to :back
  end

    # This method is used to remove message.
  def delete_message
    @message = CharitiesMassMessage.find(:first, :conditions=>["mass_message_id =? and user_info_id =?", params[:id], current_user.id])
    @message.destroy
    flash[:notice]="Message deleted successfully."
    redirect_to :back
  end



  # This method is used to remove following from the following's list.
  def remove_following
	@friend=FollowerUser.first(:conditions => "user_info_id = '#{params[:friend_id]}' && follower_id = '#{current_user.id}'")
	@friend.destroy
	#@friend.request_status='Rejected' 
	#if @friend.save
		flash[:notice]="Following deleted successfully."
		redirect_to :action=>"manage_followings"
        #end
  end

  # This method is used to remove following from the following's list.
  def remove_followers
	@friend=FollowerUser.first(:conditions => "follower_id = '#{params[:friend_id]}' && user_info_id= '#{current_user.id}'")
	@friend.destroy
	#@friend.request_status='Rejected' 
	#if @friend.save
		flash[:notice]="Follower deleted successfully."
		redirect_to :action=>"followers"
        #end
  end

   def compose_msg
	@friends = Friend.find(:all, :conditions=>["(user_info_id=#{current_user.id} or user_friend_id=#{current_user.id} )&& request_status='Accepted' "])
	
	render :update do |page|
       		page.replace_html 'compose_tab', :partial =>'users/compose' , :object => [@friends ]
    	end 
  end

  # This method is used to send a message to his friend from own friends' list.
  def send_msg
	@current_user_name = User.find_by_user_info_id(current_user.id)
	@message=Message.new(params[:message])
	@message.message_author_id = current_user.id
	@message.receiver_id= params[:id] if params[:id] && !params[:id].blank?
	if @message.save
		@receiver= User.find_by_user_info_id(@message.receiver_id).first_name
		@receiver_email= UserInfo.find_by_id(@message.receiver_id).email
		flash[:notice]="Message has been sent successfully."
		Notifier::deliver_mail_for_reply(@message,@current_user_name,@receiver,@receiver_email,request.host_with_port) 
                redirect_to :controller => "users", :action => "profile_personal_details", :id => session[:user_info_id]
	else
		flash[:notice]="Message can't be blank."
		redirect_to :controller => "users", :action => "profile_personal_details", :id => session[:user_info_id]
	end
  end

 #  --------------------------------------------My Envogue  Section ---------------------------------------------------#
 # Added by Abhijeet Ghude on 17th sep 2011
 # To show deals buy feeds
 # Ref:ApplicationController:menu_selector,require_user
 def my_envogue_home
    session[:user_info_id] = params[:id].to_i if params[:id]
    check_session_user
    if  params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
         friend_feeds
    end
  value= (params[:useractivity]=="false")? '' : session[:user_info_id]
      if !@friends_info_id.blank?
        @orders = Order.find(:all, :conditions=>["(privacy != 1 || privacy is null) && (buyer_id='#{value}' or buyer_id in (#{@friends_info_id.join(',')})) && ((store_used is not true) || (store_used is null)) "] , :order => "created_at DESC")
         deal_ids = []
         deal_ids = user_buy_deals(current_user.id)
         @friends_info_id.each do |id|
           deal_ids + user_buy_deals(id)
         end
         @deals = Deal.find_by_sql(["SELECT * FROM deals WHERE (deal_status = 'activated' OR deal_status = 'expired' OR deal_status = 'closed') && id in (?)", deal_ids])
      else
        @orders = Order.find(:all, :conditions=>["(privacy != 1 || privacy is null) && buyer_id='#{value}' && ((store_used is not true) || (store_used is null)) "] , :order => "created_at DESC")
        @deals = Deal.find_by_sql(["SELECT * FROM deals WHERE (deal_status = 'activated' OR deal_status = 'expired' OR deal_status = 'closed')"])
      end
      @orders << @deals
      @orders = @orders.flatten
      @category =  (params[:id] == 'Food')? 'Restaurant' : 'Store'
      @details= []
      @details_privacy= []
      for order in @orders
        if order.class.to_s != "Deal"
          for details in order.order_details
            @details << details if details.item.category.root.name== @category
          end
        else
          qty = deal_applicant_qty(order.id)
          order.description = qty if qty
          date = recent_deal_buying_date(order.id)
          order.updated_at = date if date
          @details << order if qty != false && date
        end
      end if @orders
      for details in @details
        if details.class.to_s != "Deal"
    @details_privacy << details if (details.order.privacy != 1) || (details.order.buyer_id == current_user.id)
        else
          @details_privacy << details
        end
      end
      @details_privacy.sort! {|a, b|
        response = 0
        if a.updated_at && b.updated_at
          if a.updated_at > b.updated_at then response = -1 end
          if b.updated_at > a.updated_at then response = 1 end
        end
        response
      }
      @details= @details_privacy.paginate(:page => params[:page], :per_page => 7)
      session[:access_tab] = "user"
      session[:sub_menu] = "shopping" if !params[:type_id]
      session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
  end

  # This method is used to create the feeds for latest favourites.
  # Ref:ApplicationController:menu_selector,require_user
  def my_envogue_for_favourite       
    session[:sub_menu] = "favourite"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]
    if params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
       friend_feeds
    end
    check_session_user
    value= (params[:useractivity]=="false")? '' : session[:user_info_id]
    query= 	(@friends_info_id.blank?)? "" : " or user_info_id in (#{@friends_info_id.join(',')})"
    @favourites=Favourite.paginate(:all, :conditions => ["user_info_id='#{value}' "+query] , :order => "created_at DESC",:page => params[:page], :per_page => 7)
  end

  

 # This method is used to create the feeds for adding a new product.
 # Ref:ApplicationController:menu_selector,require_user
  def my_envogue_for_product_update
    session[:sub_menu] = "new_item"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]
    if params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
       friend_feeds
          end
    check_session_user
          value= (params[:useractivity]=="false")? '' : session[:user_info_id]
    query= 	(@friends_info_id.blank?)? "" : " or seller_id in (#{@friends_info_id.join(',')})"
    @total_items=[]
    @items=Item.find(:all, :conditions=> ["item_status='#{"approved"}' AND (publish=1 OR publish is NULL) AND (seller_id='#{value}' "+query+")"], :order => "created_at DESC")
    for item in @items
      if item.item_status == 'approved'
      @total_items << item if item.category.root.name == 'Store'
      end
    end
    @total_items=@total_items.paginate(:page => params[:page], :per_page => 7)
  end

  
  # This method is used to create the feeds for donations.
  # Ref:ApplicationController:menu_selector,require_user
  def my_envogue_for_donation
    @donation_array = []
    session[:sub_menu] = "charity"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]
          if params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
             friend_feeds
          end
    check_session_user
    value= (params[:useractivity]=="false")? '' : session[:user_info_id]
    query= 	(@friends_info_id.blank?)? "" : " or user_info_id in (#{@friends_info_id.join(',')})"
    @donation=Donation.find(:all, :conditions => ["(privacy != 1 OR privacy is null) AND user_info_id='#{value}' "+query] , :order => "created_at DESC")
    @donation.each do |donation|
    @donation_array << donation if (donation.privacy != 1) || (donation.user_info_id.to_i == current_user.id.to_i)
    end
    @donation = @donation_array.paginate(:page => params[:page], :per_page => 7)
  end
   

  # This method is used to create the feeds for donations.
  # Ref:ApplicationController:menu_selector
  def my_envogue_charity_messages
    session[:user_info_id] = params[:id].to_i if params[:id]
    @friends_info_id =[]
    check_session_user
    @friends_info_id << session[:user_info_id] if (params[:useractivity] == "true" || params[:useractivity].blank?)
    @envogue_messages= UserInfo.envogue_mass_messages(@friends_info_id).paginate(:page => params[:page], :per_page => 7)
  end
  

 # This method is used to create the feeds for bids.
 # Ref:ApplicationController:menu_selector
  def my_envogue_for_bids
    session[:sub_menu] = "bid"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]
    if params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
       friend_feeds
    end
    check_session_user
    value= (params[:useractivity]=="false")? 'null' : session[:user_info_id]
    query= 	(@friends_info_id.blank?)? "" : " or bidder_id in (#{@friends_info_id.join(',')})"
    @bids=Bid.find(:all, :order => "created_at DESC")
    @details_privacy = []
    bid_array = []
    for bid in @bids
      bid_array << bid.id
    end
    @bid_details=(bid_array != [])? BidDetail.find(:all, :conditions =>["(privacy != 1 OR privacy is null) AND bidder_id = #{value} and bid_id  in (#{bid_array.join(',')})"+query], :order => 'created_at DESC') : []
    for bid_details in @bid_details
	@details_privacy << bid_details if (bid_details.privacy != 1) || (bid_details.bidder_id.to_i == current_user.id.to_i)
    end
    @bid_details= @details_privacy.paginate(:page => params[:page], :per_page => 7)
  end

  # Abhijeet Ghude 2011/01/07
  # method for blogs feed
  # Ref:ApplicationController:menu_selector
  def my_envogue_for_blog
     @blog_array = []
    session[:sub_menu] = "blog"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]
    if params[:useractivity] == "false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
      friend_feeds
    end
    check_session_user
    value = (params[:useractivity] == "false")? '' : session[:user_info_id]
    query = (@friends_info_id.blank?)? "" : " or user_info_id in (#{@friends_info_id.join(',')})"
    # created blogs
    @blog_created = Blog.find(:all, :conditions => ["user_info_id = '#{value}' "+query])
    @blog_created.each do | blog_created |
      @blog_title = "created"
      @blog_array << blog_created
    end
    @blog_array = @blog_array | @blog_array
    # sorting of blog feeds
    @blog_array.sort! {|a, b|
        response = 0
        a_col = ((a[:@blog_title] && @blog_title == "created") || (a[:content_type] && a.content_type == "created_picture") || (a[:url] && a.url == "created_video") || (a[:description] && a.description == "created_description"))? "created_at" : "updated_at"
        b_col = ((b[:@blog_title] && @blog_title == "updated") || (b[:content_type] && b.content_type == "created_picture") || (b[:url] && b.url == "created_video") || (b[:description] && b.description == "created_description"))? "created_at" : "updated_at"
        if a.send(a_col) && b.send(b_col)
        if a.send(a_col) > b.send(b_col) then response = -1 end
        if b.send(b_col) > a.send(a_col) then response = 1 end
        end
        response
    }
    @blog = @blog_array.paginate(:page => params[:page], :per_page => 6)
  end

  # Abhijeet Ghude 2010/12/21
  # method for tagged photo feed and pics feed
  # Ref:ApplicationController:menu_selector
  def my_envogue_for_pic
    session[:sub_menu] = "blog"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]

    if params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
      friend_feeds
    end

    check_session_user
    value= (params[:useractivity]=="false")? '' : session[:user_info_id]
    query= 	(@friends_info_id.blank?)? "" : " or a.user_info_id in (#{@friends_info_id.join(',')})"
    query_tag= 	(@friends_info_id.blank?)? "" : " or user_id in (#{@friends_info_id.join(',')})"
    @albums_all=Album.find_by_sql("select a.user_info_id, b.filename,b.id as pict_id, b.updated_at, a.id, b.parent_id from albums a LEFT JOIN pictures b ON a.id=b.album_id where a.user_info_id='#{value}' #{query} and album_id is not null order by b.updated_at DESC")
    @albums = []
    @all_data=[]
    @all_data = @albums_all   
    @tagging=TaggingPhoto.find_by_sql("select * from tagging_photos where user_id='#{value}' #{query_tag} order by updated_at DESC")
    @all_data << @tagging
    @all_data = @all_data.flatten
    @all_data.sort! {|a, b|
        response = 0
        if a.updated_at && b.updated_at
        if a.updated_at > b.updated_at then response = -1 end
        if b.updated_at > a.updated_at then response = 1 end
        end
        response
    }
    @all_data = @all_data.paginate(:page => params[:page], :per_page => 6)
  end

# Abhijeet Ghude 2010/11/19
# method for tagged photo feed   
  def my_envogue_for_tag
    session[:sub_menu] = "blog"
    session[:top_menu] = (current_user && (current_user.id.to_i == session[:user_info_id].to_i))? "envogue" : "find_people"
    session[:user_info_id] = params[:id].to_i if params[:id]
    if params[:useractivity]=="false" || (params[:useractivity].blank? && current_user.id.to_i == session[:user_info_id].to_i)
      friend_feeds
    end
    check_session_user
    value= (params[:useractivity]=="false")? '' : session[:user_info_id]
    query= 	(@friends_info_id.blank?)? "" : " or user_id in (#{@friends_info_id.join(',')})"
    @tagging=TaggingPhoto.find(:all, :conditions => ["user_id='#{value}' "+query] , :order => "created_at DESC")
    @tagging = @tagging.paginate(:page => params[:page], :per_page => 6)
  end
  


  # This method is used to create the subscribed feeds for friends of login user.
  # Ref: USersController:my_envogue_home,my_envogue_for_favourite,my_envogue_for_product_update,my_envogue_for_donation,my_envogue_for_bids,my_envogue_for_blog,my_envogue_for_pic,my_envogue_for_tag
  def friend_feeds
    
    @subscription = (current_user.id == session[:user_info_id])? FollowerUser.find(:all, :conditions => ["follower_id = '#{current_user.id}' && status = 'Accepted'"] ): FollowerUser.find(:all, :conditions => ["follower_id = '#{session[:user_info_id]}' && status = 'Accepted'"] )
    @friends_info_id=[]
    if !@subscription.blank?
      for subscription in @subscription
        @friends_info_id << subscription.user_info_id if subscription.user_info_id
      end
    
    end
   
  end

  # This method is used to subscribe the feeds of a friend by login user.
  def subscribe_feeds
    @subscription=Subscription.new
    @subscription.subscribed_by = current_user.id
    @subscription.friend_id = params[:id]
    @subscription.status = '1'
    if @subscription.save
      flash[:success_msg]=" Your request has been sent successfully."
      redirect_to :back
    end  
  end


  #  ---------------------------------------------- End ----------------------------------------------------------------

  # This method is used to add a store, charity or an item in his favourite list.
  def mark_as_favourite
	@favourites=Favourite.new                             
    if !params[:id].blank?
      @favourites.my_favourite_id = params[:id]
      @favourites.user_info_id= current_user.id
      if (params[:type] && params[:type] == "charity")
        @type= 'char'
      else
        @type= (  !params[:type].blank? ) ? 'store' : 'item'
      end
      @favourites.favourite_type= @type
                  @favourites.privacy= current_user.user.privacy
      if @favourites.save
        flash[:notice]="Your request has been sent successfully."
        redirect_to :back
      end
    end
  end

  # This method is used to find the favourites of the registered user.
=begin
  def my_favourites
    if params[:id] == current_user.id.to_s
		session[:user_info_id] = params[:id].to_i
		@favourites=Favourite.paginate(:all, :conditions => ["user_info_id='#{params[:id]}' "] , :order => "created_at DESC",:page => params[:page], :per_page => 7)
    else
	if !params[:id].blank? 
		 @user_info = UserInfo.find_by_id(params[:id]) 
	else 
		 @user_info = UserInfo.find_by_id(current_user.id) 
		 params[:id] = @user_info.id 
	end 
		@favourites=Favourite.paginate(:all, :conditions => ["user_info_id='#{params[:id]}' "] , :order => "created_at DESC",:page => params[:page], :per_page => 7)
     end
     check_for_active_tab
  end
=end

  # modified code on date 09-09-2010 by Saurabh
  # Ref:ApplicationController:top_menu_selector(tab),menu_selector
  def my_favourites
        if !current_user.blank? && params[:id] &&  (current_user.account_type=="admin" && current_user.id.to_s == params[:id])
                session[:user_info_id] = (!params[:id].blank?)? params[:id].to_i : current_user.id.to_i
        	redirect_to :action => "profile_personal_details", :id=>current_user.id
        else

 		session[:user_info_id] = (!params[:id].blank?)? params[:id].to_i : current_user.id.to_i
		@favourites=Favourite.paginate(:all, :conditions => ["user_info_id='#{session[:user_info_id]}' "] , :order => "created_at DESC",:page => params[:page], :per_page => 7)
        	check_for_active_tab
        end
  end

  # This method is used to find the favourites of the registered user.
  def delete_favourites
    @favourites = Favourite.find(params[:id])

    #########
    #Modified by Jalendra on 17/11/11
    if(@favourites.favourite_type == "site")
      @site = FavoriteSite.find(@favourites.my_favourite_id)
    end

    if  @favourites.destroy
        @site.destroy if  @site
    end
    ##########

    flash[:message] = "Favourites deleted successfully"
    redirect_to :back
  end

  # This method is used to post a scrap to his friend by a registered user.
  def post_scrap
	if ! params[:message][:message_author_id].blank?
		@message=Message.new(params[:message])
		@message.message = params[:scrap][:scrap]
		render :update do |page|
			if @message.save
				 flash="Message has been sent successfully."
				 page.replace_html "notice_#{params[:message_id]}", "<span class='flash'>#{flash}</span>" #<span style='color:red'>#{flash}</span>"
				 page.hide "reply_#{params[:message_id]}"
				 page.hide "replytext_#{params[:message_id]}"
			else
				 flash=(@message.message.match(/^[A-Z a-z 0-9. ~ ` ! @ # $ % ^ & * ( ) _ \- + = { } ' : ; " ' ? , | \[ \] \\ \/ ]*\z/).nil?) ? "Please don't enter html code." : "Reply can't be blank."
				 page.replace_html "notice_#{params[:message_id]}", "<span style='color:red'>#{flash}</span>"
				 page.show "reply_#{params[:message_id]}"
				 page.show "replytext_#{params[:message_id]}"
			end 
		end
	else
		@message = Message.new
		@message.message = params[:message][:scrap]
		@message.message_author_id = current_user.id
		@message.access = 'Public'
		@receiver = session[:user_info_id] ? session[:user_info_id] : current_user.id
		@message.receiver_id = @receiver
		if @message.save
			flash[:notice]="Scrap has been sent successfully."
			redirect_to :back
		else
			flash[:notice]=(@message.message.match(/^[A-Z a-z 0-9. ~ ` ! @ # $ % ^ & * ( ) _ \- + = { } ' : ; " ' ? , | \[ \] \\ \/ ]*\z/).nil?) ? "Please don't enter html code." : "Please enter message into the textarea."
			redirect_to :back
		end 
	end

  end

  # This method is used to provide rating to any purchased item.
  def provide_rating
	@rating=Rating.new(params[:rating])
	@rating.order_detail_id= params[:id] if params[:id] && !params[:id].blank?
	if !params[:rating][:rate].blank? && @rating.save
		flash[:notice]="Rating has been done successfully."
		redirect_to :back
	else
		flash[:notice]="Please select rating."
		redirect_to :back
	end
  end

  # This method is used to display the comments given by the buyers on any product.
  def buyers_review
	@order_details=OrderDetail.find(:all, :conditions=>["item_id='#{params[:id]}' "])
	 session[:user_info_id] = params[:session_user].to_i
  end

  # 21/11/2009
  # This method is used to follow a user
  def follow
    @friend=FollowerUser.new
    @friend.user_info_id = params[:id]
    @friend.follower_id = current_user.id
    @user_info = UserInfo.find_by_id(params[:id])
    @privacy = User.find_by_user_info_id(params[:id])
    host_port= request.host_with_port
    @friend.status = (@user_info.user.access == "private")? 'Pending':'Accepted'
    if @friend.save
      flash[:notice]=(@friend.status == "Accepted")? "You became a follower of #{@user_info.login.username}.":"Your follower request is sent to #{@user_info.login.username}."
      redirect_to :controller => :users, :action => :profile_personal_details, :id => params[:id]
      Notifier::deliver_follower_info(@user_info.email, current_user.login.username, @user_info.login.username,host_port, @privacy.access)
    end
  end
  # This method is used so that the user can select his privacy settings
  def privacy
       check_for_active_tab
	@user_info=UserInfo.find(current_user.id )
 	@user = @user_info.user
  end

  # Ref:ApplicationController:menu_selector
  def update_privacy
        @user_info=UserInfo.find(current_user.id )
	@user = @user_info.user
        @user.privacy = (params[:hide_username] == "1")? 1 : (params[:hide_amount] == "1")? 2 : 0
        @access = (params[:mark] == "1")? "private":"public"	
	@user.access = @access
	@user.save	
	flash[:notice]="Privacy settings has been updated successfully."
	redirect_to :action => "privacy", :id => current_user.id
  end


   # Method sfor daily deal tab
 #Deepali Thaokar
 def daily_deal
    session[:sub_menu] = "deal"
    session[:top_menu] =  "deal"
    session[:access_tab] = "user"
     @deal = Deal.find(:all,:conditions=>["(deal_status = 'approved') OR (deal_status = 'activated') OR (deal_status = 'closed')"], :order => 'deal_end_date' )
 end

 # to select active tab of deals past and present
 def set_active_tab
   if params[:id] == "present"
     session[:deal_tab] = "present"
   else
     session[:deal_tab] = "past"
   end
   render :text=>"" 
 end

 # to select order tab of deals past and present
 def set_order_tab
   if params[:id] == "order"
     session[:deal_order_tab] = "order"
   else
     session[:deal_order_tab] = "deal_order"
   end
   render :text=>"" 
 end

 #++
 #Created by : Jalendra Bhanarkar
 #Created on : 17/11/11
 #Purpose    : To add the favorite site
 #--
 def add_fav_site
      if params[:site]
        @site = FavoriteSite.new(params[:site])
        if @site.save
          @favorite = Favourite.new(:my_favourite_id=>@site.id, :favourite_type=>"site", :user_info_id=>current_user.id)
          @favorite.save
         #render :partial => "my_favorite_table"
         redirect_to :action => "my_favourites", :id => current_user.id.to_s
        else
          flash[:error_message] = @site.errors
          redirect_to :action => "my_favourites", :id => current_user.id.to_s
        end
      else
          redirect_to :action => "my_favourites", :id => current_user.id.to_s
      end
 end
end
