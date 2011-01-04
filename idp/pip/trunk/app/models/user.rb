# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# == Schema Information
# Schema version: 27
#
# Table name: users
#
#  id               :integer(11)   not null, primary key
#  login            :string(40)    
#  email            :string(100)   
#  crypted_password :string(40)    
#  salt             :string(40)    
#  activation_code  :string(40)    
#  activated_at     :datetime      
#  created_at       :datetime      
#  updated_at       :datetime      
#  identity_url     :string(255)   
#

require 'digest/sha1'

# Contains a user of the app.
# Has Trusts, Profiles, Properties, Ledgers, and an Avatar
class User < ActiveRecord::Base  
  OPENID_MAPPINGS = 
      {'nickname' => 'nickname', 'email' => 'contact_email_personal', 'fullname' => 'full_name', 'dob' => 'dob',
       'gender' => 'gender', 'postcode' => 'address_home_postal_code', 'country' => 'address_home_country',
       'language' => 'language', 'timezone' => 'timezone'} unless defined?(OPENID_MAPPINGS)
  
  attr_accessor :password       # Virtual attribute for the unencrypted password
  attr_accessor :avatar_data

  attr_protected :crypted_password, :updated_at, :created_at, :activation_code,
                 :activated_at, :salt, :identity_url

  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 5..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email
  before_save :encrypt_password
  before_create :make_activation_code
  validates_format_of       :login, :with => /^([a-z0-9-]+\.){0,2}[a-z0-9-]+$/i, :on => :create,
                            :message => 'can only contain letters, hyphen, digits, and two dots.',
                            :if => Proc.new {|user| user.login && !user.login.empty? }
  validates_format_of       :email, :with => /^[a-z0-9.+-_]+@([a-z0-9-]+(.[a-z0-9-]+)+)$/i, :on => :create,
                            :message => 'must be a proper email address.',
                            :if => Proc.new {|user| user.email && !user.email.empty? }
  validates_exclusion_of    :login, :in => %w( www ),
                            :message => "'www' is not a valid username."

  after_create  :add_global_properties
  after_save    :save_avatar
  
  has_many :ledgers,    :dependent => :destroy
  has_one  :avatar,     :dependent => :destroy
  has_many :profiles,   :dependent => :delete_all
  has_many :trusts,     :through   => :profiles
  has_many :property_types
  has_many :properties, :include => :property_type, :dependent => :delete_all do
    
    # Defined for User#properties
    # Returns true if the user has the property of type _property_type_.
    # ====Parameters
    # property_type:: The PropertyType we are checking for.
    def has_property?(property_type)
      self.to_a.any? {|p| p.property_type_id == property_type.id }
    end
    
    # Defined for User#properties
    # Find a property by its PropertyType.
    # ====Parameters
    # property_type:: Object of class PropertyType
    def find_by_property_type(property_type)
      self.to_a.detect { |p| p.property_type_id == property_type.id }
    end
    
    # Returns a hash containing a hard coding of PropertyType short names to OpenID Sreg fields.
    def openid
      OPENID_MAPPINGS
    end
    
    # Defined for User#properties
    # Use value_for_[short_name] to find the value of a property given its PropertyType short_name.
    # For example: profile.properties.value_for_nickname would return the value for the property that
    # has a PropertyType with a shortname of nickname.
    # *args:: String that matches a PropertyType.short_name
    def method_missing(sym, *args)
      return super unless sym.to_s =~ /value_for_(\w*)/
      return nil unless property_type = PropertyType.find_by_short_name($1)
      (prop = self.find_by_property_type(property_type)) ? prop.value : nil
    end
  end
  
  # Finds the global PropertyType leaf nodes and creates a new property for each of them for the user.
  def add_global_properties
    @property_types = PropertyType.find_global_leaves
    @property_types.each do |ptype|
      logger.info ptype.short_name
      self.properties << Property.new(:property_type => ptype) unless self.properties.has_property?(ptype)
    end
    self.save
  end
  
  # Authenticates a user by their login name and unencrypted password.  Returns the User or nil.
  # ====Parameters
  # login:: The User's login.
  # password:: The user's unencrypted password.
  def self.authenticate(login, password)
    u = self.find_by_login(login) # need to get the salt 
    return nil unless u
    u.authenticated?(password) ? u : nil
  end

  # Returns true if _password_ matches the User's password.
  # ====Parameters
  # password:: The User's unencrypted password.
  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  # Marks the user as activated in the database.
  # Primarily used to mark when a user's email as verified.
  def activate
    unless self.activated_at
      @activated = true
      self.activated_at = Time.now.utc
    end
    self.activation_code = nil
    self.save
  end
  
  # Returns true if the user has just been activated within the current request.
  def recently_activated?
    @activated
  end

  # Returns true if the user has verified their email address.
  def email_verified?
    !self.activated_at.nil?
  end

  # Returns the time of the User's last login as a Time object.
  # Returns Time.now if the user has not previously logged in.
  def last_login
    last_two = self.ledgers.find(:all, :conditions => "event = 'Login'", :order => 'created_at DESC', :limit => 2)
    last = !last_two.empty? ? last_two.last.created_at : Time.now.utc
    last.to_formatted_s(:short_date)
  end
  
  # Create an activation code for the user.
  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split('//').sort_by { rand }.join) unless activation_code
  end
  
  protected
  # Save the User's avatar in the database
  def save_avatar
    return unless @avatar_data && @avatar_data.size > 0
    self.avatar = Avatar.create :uploaded_data => @avatar_data
  end

  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
    self.password = self.password_confirmation = nil
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
end
