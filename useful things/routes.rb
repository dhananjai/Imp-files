ActionController::Routing::Routes.draw do |map|
  map.resources :measures

  map.resources :donations, :collection=>{
                                            :donation=>:get,
                                            :moneybooker=>:get,
                                            :confirm=>:get,
                                            :complete=>:get
                                         }

  map.resources :item_pictures

  map.resources :favourites

  map.resources :albums, :collection=>{
                                        :delete_tag=>:get
                                          
                                      }

  map.resources :delivery_trackings

  map.resources :order_details

  map.resources :order_details

  map.resources :comments

  map.resources :admins,   :collection=>{
                                          :site_users=>:get,
                                          :revenue_report=>:get,
                                          :best_reports =>:get,
                                          :que_ans => :get,
                                          :secure_admin => :get,
                                          :secure_admin => :get,
                                          :show_questions => :get,
                                          :edit_questions => :get,
                                          :update_question=>:get,
                                          :security_page => :get,
                                          :match_answers => :get,
                                          :charity_amount => :get,
                                          :pending_dues=>:get,
                                          :pay_dues=>:get,
                                          :payment_paypal=>:get,
                                          :suspend_account => :get
                                        }

  map.resources :messages
 
  map.resources :invitation , :collection=>{:my_invitations=>:get,
 					     :resend => :get
                                             } 
 
  map.resources :logins , :collection=>{
                                         :sign_up=>:get,
                                         :profile_management=>:get ,
                                         :logout=>:get,
                                         :envogue_for_favourite=>:get,
                                         :contact_us=>:get,
                                         :about_us=>:get,
                                         :auto_complete_for_order_amount=>:get,
                                         :terms => :get,
                                         :sign_up_new=>:get,
                                       :user=>:get
                                        }

  map.resources :order_returns

  map.resources :refund_policies

  map.resources :friends

 map.resources :payment_accounts , :collection=>{
                                                  :checkout=>:get,
                                                  :checkout_bid=>:get,
                                                  :reject_auction_item =>:get,
                                                  :confirm_order=>:get ,
                                                  :order_info=>:get,
                                                  :order_success=>:get,
                                                  :make_payment=> :get,
                                                  :confirm_auction_order=> :get,
                                                  :moneybooker=>:get,
                                                  :moneybooker_auction=>:get,
                                                  :buyer =>:get,
                                                  :info =>:get,
                                                  :back_to_shipping_options =>:get  
                                                  }

  map.resources :order_returns

  map.resources :orders

  map.resources :restaurants, :collection => {:search_restaurants => :get}

  map.resources :order_shipping_details

  map.resources :logistics_options

  map.resources :items, :collection=>{
                                       :mystore_my_product=>:get,
                                       :select_category =>:get,
                                       :cart=>:get,
                                       :my_bids=>:get,
                                       :multi_views=>:get,
                                       :item_pictures=>:get,
                                       :search_products=>:get,
                                       :moneybooker=>:get, 
				       :recent_buyers=>:get,:store=>:get
                                     }

  map.resources :carts, :collection=>{
                                        :add_to_cart=>:get,
                                        :delete_from_cart =>:get,
                                        :reset_auction_cart => :get,
                                        :empty_auction_cart=> :get,
                                        :empty_cart => :get
                                     }

  map.resources :user_infos

  map.resources :charities, :collection=>{
                                           :export_donors_while_buying=>:get,
                                           :export_to_excel_direct_donors=>:get,
                                           :export_to_excel_favourites=> :get,
                                           :envogue_mass_message=> :post,
                                           :show_charity=>:get,
                                           :tax_treat=>:get,
                                           :tax_update=>:get
                                         }

  map.resources :bid_details

  map.resources :bids

  map.resources :categories, :collection=>{:buy=>:get,:options => :get,:shipping=>:get,:shop=>:get, :go_back=>:get}

  map.resources :pictures, :collection=>{:profile_image=>:get}

  map.resources :users , :collection=>{
                                        :profile_personal_details=>:get,
                                        :profile_contact_details=>:get,
                                        :profile_image=>:get,
                                        :const_page=>:get,
                                        :received_requests=>:get,
                                        :sent_requests=>:get ,
                                        :manage_friends=>:get,
                                        :send_scrap=> :get,
                                        :remove_friend=>:get,
                                        :send_invitation=>:get,
                                        :my_messages=>:get,
                                        :buying_history=>:get,
                                        :orders => :get,
                                        :order_details => :get ,
                                        :privacy =>:get,
                                        :my_envogue_home=>:get,
                                        :search_friends=>:get,
                                        :buying_report => :get ,
                                        :selling_report => :get ,
                                        :my_favourites=> :get,
                                        :donation_history => :get,
                                        :buyers_review=>:get,
                                        :moneybooker=>:get,
                                        :remove_following=>:get,
                                        :manage_followings=>:get,
                                        :user_access=>:get,
                                        :search=>:get,
                                        :followers => :get,
                                        :remove_followers=>:get,
                                        :charity_messages=>:get,
                                        :privacy_radio_status=>:get,
                                        :sent_messages => :get
                                        }
  #map.users 'users/:action/:id', :controller => 'users'

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.

  map.connect '', :controller => 'logins'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
end
