class User < ActiveRecord::Base

  require 'digest/sha1'

  has_one :contact, :as => :contactable, :dependent => :destroy
  has_many :artist_users, :dependent => :destroy
  has_many :label_users, :dependent => :destroy
  has_many :artists, :through => :artist_users
  has_many :images, :as => :imaginable, :dependent => :destroy

  validates_presence_of :hashed_password
  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :on => :create, :allow_blank => true
  validates_uniqueness_of :email
  validates_associated :contact
  validates_confirmation_of :password
  validates_length_of :password, :within => 6..40, :allow_blank => true
  attr_accessor :password, :role_in_current_artist
  before_validation :update_hashed_password

  SECURITY_BONUS = 'mmm, salty passwords'
  SYSTEM_ROLE_USER = 10
  SYSTEM_ROLE_GOD = 90
  SYSTEM_ROLE_PUBLISHER= 30

  def is_god?
    self.system_role == SYSTEM_ROLE_GOD
  end

  def has_multiple_artists?
    self.is_god? || self.valid_artists.size > 1
  end

  def artist
    self.valid_artists.first
  end

  def artist_role(artist)
    au = artist_users.find_by_artist_id(artist)
    au.artist_role if au
  end

  def save_with_contact
    if self.valid_with_callbacks?
      self.save!
      self.contact.save!
      return true
    end

    return false
  end

  def after_validation
    if self.errors[:hashed_password]
      self.errors.add(:password, "can't be blank") unless self.errors[:password]
    end

    self.contact.errors.each { |field, message|
      self.errors.add(field, message)
    } if self.contact

    self.artist_users.each { |artist|
      artist.errors.each { |field, message|
        self.errors.add(:role_in_current_artist, message)
      }
    }

    # Skip errors that won't be useful to the end user
    filtered_errors = self.errors.reject{ |err| %w{ artist_users contact hashed_password }.include?(err.first) }
    self.errors.clear
    filtered_errors.each { |err| self.errors.add(*err) }
  end

  #def valid_artists
    #return Artist.find(:all, :order => "name") if is_god?
    #return self.artists.find(:all, :order => "name")
  #end

  #Checks for active artist
  # FIXME: The session variable should only be used in controllers and views.
  def valid_artists
   if is_god? && (session[:valid_label] == 'no_label' || session[:valid_label].nil?)
    return Artist.find(:all, :conditions => ["status !=?", "new"], :order => "name")
   elsif session[:valid_label] != 'no_label' && !session[:valid_label].nil?
    return Artist.find(:all, :conditions => ["label_id =? && status =? ", "#{session[:valid_label]}",'active'], :order => "name")
   else
    return self.artists.find(:all, :conditions => ["status =?", "active"], :order => "name")
   end
  end

  # due to unavailable of session variable by cron, this method is created
  def find_temp_valid_artists
    return Artist.find(:all, :conditions => ["status !=?", "new"], :order => "name")
  end

  # Class methods
  def self.authenticate(u, p)
    self.find_by_email_and_hashed_password(u, self.hash_password(p))
  end

  def self.authenticate_with_hashed_password(u, p)
    self.find_by_email_and_hashed_password(u, p)
  end

  def self.hash_password(p)
    Digest::SHA1.hexdigest("#{p}#{SECURITY_BONUS}")
  end

  def self.create_admin(email, pass)
    self.create(:email => email, :hashed_password => self.hash_password(pass), :system_role => 90)
  end

  private
    def update_hashed_password
      self.hashed_password = self.class.hash_password(password) unless password.blank?
    end

    # method_missing tries to pass to the contact information for this user
    def method_missing(method_id, *args, &block)
      method_name = method_id.to_s
      # Perform a hand-off to AR::Base#method_missing
      if @attributes.include?(method_name) or @attributes.include?(method_name.gsub('=','')) or @attributes.include?(method_name.gsub('_before_type_cast',''))
        super(method_id, *args, &block)
      else
        self.contact ||= Contact.new
        self.contact.send(method_id, *args, &block)
      end
    end


  def self.delete_incorrect_user
    log = Logger.new("#{RAILS_ROOT}/private/DeleteUser.log")
    label = Label.find_by_name("gagan")
    puts "label id"
    puts label.id 
    artist = Artist.find(:all,:conditions=>["label_id = #{label.id}"])
    artist.each do |artist|
      puts "artist id"
      puts artist.id 
      
      album = Album.find(:all,:conditions=>["artist_id = #{artist.id}"])
      album.each do |album|
        puts "album id"
        puts album.id
        track = Track.find(:all,:conditions=>["album_id = #{album.id}"])
        track.each do |track|
          puts "tracks id"
          puts track.id
          track_file = TrackFile.find(:all,:conditions=>["track_id = #{track.id}"]) 
          track_file.each do |track_file|
          puts "track file"
          puts track_file.id
          end
	  asset = Asset.find(:all,:conditions=>["track_id = #{track.id}"]) 
            asset.each do |asset|
              puts "asset"
              puts asset.id    
	      path_upto_asset = "#{RAILS_ROOT}/private/assets"  
              s3_filename = asset.amazon_s3_filename
              aset_file = path_upto_asset + "/" + s3_filename
                if File.exists?(aset_file)
	          FileUtils.rm aset_file
	          log.debug "deleted asset from file system"
	          UnwantedAssetDelete.delete_other_file(aset_file)             
                end             
                if track_file.amazon_s3 = "transferred"
                  AssetCreate.connect_to_amazon_s3
	          AssetCreate.move_files_to_s3
               end 
               asset.delete 
               log.debug "deleted asset from database" 
            
               track_file = TrackFile.find(:all,:conditions=>["track_id = #{track.id}"])      
               track_file.each do |track_file|           
                 track_fle = track_file.filename
                 @sub_file_folder = prefix_sub_file_folder(track_fle.id)
                 @file_folder = prefix_file_folder(track_fle.id)
                 track_path= "#{RAILS_ROOT}/private/tracks/original/#{@file_folder}/#{@sub_file_folder}"
	         track_file_path = track_path + "/" + track_fle
                 if File.exists?(track_fle)
                   FileUtils.rm track_fle
                   log.debug "deleted track file from file system"
	           FileUtils.rm_rf("#{@sub_file_folder}") if (Dir.entries("#{@sub_file_folder}")-["..", "."]).empty?             
                end
              end
              track_file.delete
	      log.debug "deleted track file from database"      
            end
        end
      end 
    end
    user = ArtistUser.find(:all,:conditions=>["artist_id = #{artist.id}"])
      puts "user id"
      user.each do |user|        
        puts user.user_id 
        contact = Contact.find(:all,:conditions=>["contactable_id = #{user.id}"])
        puts "contact to delete"
        contact.each do |contact|          
          puts contact.id
        end
      end 
     puts album.images
  end


  
end
