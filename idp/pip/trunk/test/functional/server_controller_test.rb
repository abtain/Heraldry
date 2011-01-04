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

require File.dirname(__FILE__) + '/../test_helper'
require 'server_controller'

# Re-raise errors caught by the controller.
# class ServerController; def rescue_action(e) raise e end; end
 class ServerController; def local_request?() false end; end

class ServerControllerTest < Test::Unit::TestCase
  include OpenIdTestMethods

  fixtures :users, :profiles, :property_types, :properties, :profiles_properties, :trusts, :globalize_languages
  
  def setup
    @controller = ServerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @server = OpenID::Server::Server.new(ActiveRecordOpenIDStore.new)
  end
  
  def test_decision_with_no_trust_profile
    login_as 'quentin'
    post_without_ssl :decision, :yes => true, :trust_profile => nil, :query => create_checkid_query_string
    assert_redirected_to :controller => 'profiles', :action => 'new'
  end

  def test_index_error_page
    login_as 'quentin'
    post_without_ssl :index, create_checkid('openid.trust_root' => 'http://bad/')
    assert_response 500
    assert_match 'The Request that you', @response.body
  end

  def test_not_logged_in
    post_without_ssl :index, create_checkid
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'login'
  end 
  
  def test_already_logged_in
    @request.env['QUERY_STRING'] = create_checkid_query_string
    login_as 'quentin'
    post_without_ssl :index, create_checkid
    assert_trust_request
  end
  
  def test_decision_with_no_request_data
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => -1
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'welcome'
  end
  
  def test_already_trusted
    login_as 'quentin'
    trust = Trust.create :profile => users(:quentin).profiles.find(4), :expires_at => 1.month.from_now, :trust_root => 'http://localhost:2000/'
    assert trust.valid?
    post_without_ssl :index, create_checkid
    assert_response :redirect
  end
 
  def test_no_trust_root
    login_as 'quentin'
    post_without_ssl :index, create_checkid('openid.trust_root' => nil)
  end

  def test_not_duplicating_openid_sreg
    login_as 'quentin'
    args = {'openid.sreg.required' => 'nickname,email', 'openid.sreg.optional' => 'fullname'}
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :query => create_checkid_query_string(args)

    assert_response :redirect
    assert_location_no_match( /openid\.sreg\.openid\.sreg\.nickname=nickname/)
    assert_location_no_match( /openid\.sreg\.openid\.sreg\.email=quentin@quentin.com/)
    assert_location_no_match( /openid\.sreg\.openid\.sreg\.fullname=fullname/)
  end

  def test_returning_only_fields_requested
    login_as 'quentin'
    args = {'openid.sreg.required' => 'nickname,email', 'openid.sreg.optional' => 'fullname'}
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :query => create_checkid_query_string(args)

    assert_response :redirect
    assert_location_match( /openid\.sreg\.nickname=nickname/)
    assert_location_match( /openid\.sreg\.email=quentin@quentin.com/)

    # Ensure that no other openid 1.2 fields are included.
    ['dob', 'gender', 'postcode', 
     'country', 'language', 'timezone'].each {|s| assert_location_no_match(/openid\.sreg\.#{s}/)}

    # Ensure that no other fields from the trust profile are included.
    profile = Profile.find(4)
    profile.properties.each do |p| 
      sn = p.property_type.short_name
      assert_location_no_match(/openid\.sreg\.#{sn}/) unless ['nickname', 'email', 'fullname'].include?(sn)
    end
  end
  
  def test_profile_has_required_fields
    login_as 'quentin'
    assert_difference Trust, :count do 
      post_without_ssl :decision, :"yes.y" => true, :trust_profile => 1, :query => create_checkid_query_string
      
      assert_response :redirect
    end
  end
  
  def test_profile_never_expires
    login_as 'quentin'
    assert_difference Trust, :count do
      post_without_ssl :decision, :"yes.y" => true, :keep_until => 'forever', :trust_profile => 4, :query => create_checkid_query_string
      assert_response :redirect
    end
  end

  def test_check_authentication
    assert_check_authentication
  end

  def test_check_authentication_with_nil_email
    assert_check_authentication('openid.sreg.email' => nil)
  end
  
  def test_creates_trust_if_old_trusts_not_active
    assert trusts(:past_expiration).valid?
    assert !trusts(:past_expiration).active?
    login_as 'quentin'
    args = {'openid.trust_root' => trusts(:past_expiration).trust_root,
            'openid.return_to' => trusts(:past_expiration).trust_root}
    assert_no_difference Trust, :count do
      post_without_ssl :decision, :"yes.y" => true, :keep_until => 2, :trust_profile => trusts(:past_expiration).profile_id,
                      :query => create_checkid_query_string(args)
      assert assigns(:trust)
      assert_not_equal trusts(:past_expiration).expires_at, assigns(:trust).expires_at
      assert_response :redirect
    end
  end
  
  def test_create_new_profile
    login_as 'quentin'
    open_id = PropertyType.find_by_short_name('openid_sreg')
    properties = users(:quentin).properties.delete_if{ |p| !(['nickname', 'email'].include?(p.property_type.short_name) && 
                                                            p.property_type.parent == open_id)}
    assert_difference Profile, :count do
      post_without_ssl :decision, :"yes.y" => true, :trust_profile => -1, :property => properties.map{|p| p.id}, :profile_name => 'Brand New',
                      :query => create_checkid_query_string
      assert_response :redirect
    end
  end
  
  def test_user_owns_identity
    login_as 'quentin'
    post_without_ssl :index, create_checkid('openid.identity' => 'http://test.host/user/trotter')
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'login'
    assert_not_nil session[:return_to]
  end

  def test_user_owns_identity_with_restricted_login_with_trailing_slash
    login_as 'two_dots'
    post_without_ssl :index, create_checkid('openid.identity' => 'http://linda.joe.turner/')
    assert_response :success
  end
  
  def test_user_owns_identity_with_restricted_login_without_trailing_slash
    login_as 'two_dots'
    post_without_ssl :index, create_checkid('openid.identity' => 'http://linda.joe.turner')
    assert_response :success
  end
  
  def test_case_insensitivity
    @request.env['QUERY_STRING'] = create_checkid_query_string
    login_as 'quentin'
    post_without_ssl :index, create_checkid('openid.identity' => 'http://test.host/user/QUENTIN')
    assert_trust_request
  end
  
  def test_user_owns_subdomain
    @request.env['QUERY_STRING'] = create_checkid_query_string
    login_as 'quentin'
    post_without_ssl :index, create_checkid('openid.identity' => 'http://quentin.test.host/')
    assert_trust_request
  end
  
  def test_duplicate_profile_name
    login_as 'quentin'  
    open_id = PropertyType.find_by_short_name('openid_sreg')
    properties = users(:quentin).properties.delete_if{ |p| !(['nickname', 'email'].include?(p.property_type.short_name) && 
                                                            p.property_type.parent == open_id)}  
    assert_no_difference Profile, :count do
      post_without_ssl :decision, :"yes.y" => true, :trust_profile => -1, :property => properties.map{|p| p.id}, 
                      :profile_name => profiles(:openid).title, :query => create_checkid_query_string
      assert_trust_request
    end
  end
  
  def test_wildcard_trust_root_existing_trust
    login_as 'quentin'
    Trust.create :profile => profiles(:openid), :expires_at => nil, :trust_root => 'http://localhost:2000/'
    post_without_ssl :index, create_checkid('openid.trust_root' => 'http://*.localhost:2000/',
                                'openid.return_to' => 'http://test.localhost:2000/')
    assert_response :success
  end
  
  def test_checkid_immediate_does_not_redirect_to_login
    post_without_ssl :index, create_checkid('openid.mode' => 'checkid_immediate')
    assert_response :redirect
    assert_location_match %r[openid\.mode=checkid_setup]
  end
  
  def test_checkid_immediate_creates_correct_setup_url
    post_without_ssl :index, create_checkid('openid.mode' => 'checkid_immediate')
    assert_response :redirect
    assert_location_no_match %r[openid\.mode=checkid_immediate]
  end

  def test_returning_null_properties
    login_as 'quentin'
    args = {'openid.sreg.required' => 'country'}
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :query => create_checkid_query_string(args)
    assert_response :redirect
    assert_location_match %r[openid\.mode=id_res]
    assert_location_match %r[sreg\.country]
  end
  
  def test_returning_blank_properties
    login_as 'quentin'
    args = {'openid.sreg.required' => 'postcode'}
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :query => create_checkid_query_string(args)
    assert_response :redirect
    assert_location_match %r[openid\.mode=id_res]
    assert_location_match %r[sreg\.postcode]
  end
  
  # This test is not very effective due to an issue with reload and assert_no_difference
  def test_decision_with_blank_profile_name
    login_as 'quentin'
    
    assert_no_difference users(:quentin).profiles, :count do
      post_without_ssl :decision, :"yes.y" => true, :trust_profile => -1, :profile_name => '', :query => create_checkid_query_string
      assert_trust_request
    end
  end
  
  def test_decision_with_blank_profile_name_and_keep_once
    login_as 'quentin'
    
    assert_no_difference users(:quentin).profiles, :count do
      post_without_ssl :decision, :"yes.y" => true, :trust_profile => -1, :profile_name => '', :keep_until => 'once',
                      :query => create_checkid_query_string
      assert_response :redirect
    end
  end
    
  def test_decision_with_nonexistant_profile
    login_as 'quentin'
    assert_nil Trust.find_by_id(100)
    assert_nothing_raised { post_without_ssl :decision, :"yes.y" => true, :trust_profile => 100, :query => create_checkid_query_string }
    assert_trust_request
  end
  
  def test_second_users_decision_does_not_overwrite_firsts
    login_as 'quentin'
    assert_difference Trust, :count do
      post_without_ssl :decision, :"yes.y" => true, :keep_until => 'forever', :trust_profile => 4, :query => create_checkid_query_string
      assert_response :redirect
    end
    
    # Must reload the controller to be able to login as another user.
    @controller = ServerController.new
    
    login_as 'arthur'
    post_without_ssl :decision, :"yes.y" => true, :keep_until => 'once', :trust_profile => -1, 
                   :query => create_checkid_query_string("openid.identity"=>"http://test.host/user/arthur")
    assert_response :redirect
    
    # If overwritten, the profile_id will be nil
    assert_not_nil Trust.find_by_trust_root("http://localhost:2000/").profile_id
  end
  
  def test_get_association_blank_session_type
    assert_get_association('openid.session_type' => nil)
    assert_match /mac_key:.*/, @response.body
  end
  
  def test_date_format
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                    :query => create_checkid_query_string('openid.sreg.required' => 'dob')
    assert_location_match /dob=1983-04-05/
  end

  def test_email_format
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                    :query => create_checkid_query_string('openid.sreg.required' => 'email')
    assert @response.headers['location'] =~ /email=(.*?)&/
    assert_match /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, CGI::unescape($1)
  end
  
  def test_email_format_bad_email
    properties(:openid1).update_attribute(:value, 'quentin@quentin')
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                    :query => create_checkid_query_string('openid.sreg.required' => 'email')
    assert @response.headers['location'] =~ /email=(.*?)&/
    assert_equal '', $1
  end    

  def test_gender_format
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                    :query => create_checkid_query_string('openid.sreg.required' => 'gender')
    assert_location_match( /gender=m&/)
  end
  
  def test_timezone_format
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once', 
                    :query => create_checkid_query_string('openid.sreg.required' => 'timezone')
    assert_location_match( %r[timezone=America/Los_Angeles])
  end
 
  def test_custom_timezone_formats
    login_as 'quentin'
    [['us_eastern', 'America/New_York'], ['us_central', 'America/Chicago'], 
     ['us_mountain', 'America/Denver'], ['us_pacific', 'America/Los_Angeles']].each do |property, output|
      properties(:openid9).update_attribute(:value, property)
      post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                       :query => create_checkid_query_string('openid.sreg.required' => 'timezone')
      assert_location_match( %r[timezone=#{output}] )
    end
  end

  def test_language_format
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                    :query => create_checkid_query_string('openid.sreg.required' => 'language')
    assert_location_match( /language=eng/)
  end
  
  def test_country_format
    login_as 'quentin'
    post_without_ssl :decision, :"yes.y" => true, :trust_profile => 4, :keep_until => 'once',
                    :query => create_checkid_query_string('openid.sreg.required' => 'country')
    assert_location_match( /country=US/)
  end
  
  def assert_location_match(regex)
    assert_match regex, CGI::unescape(@response.headers['location'])
  end
  
  def assert_location_no_match(regex)
    assert_no_match regex, CGI::unescape(@response.headers['location'])
  end
  
  def assert_trust_request
    assert_response :success
    assert_template 'trust_request'
    [:openid_request, :required_fields, :optional_fields, :properties,
     :trust_root, :identity_url, :query_string].each { |item| assert_not_nil assigns(item), "#{item} expected to not be nil." }
  end
  
  def assert_get_association(args={})
    body = {'openid.mode' => 'associate', 'openid.assoc_type' => 'HMAC-SHA1'}.merge(args)
    post_without_ssl :index, body
    assert_response :success
    assert_match /assoc_type:HMAC-SHA1/, @response.body
    assert_match /assoc_handle:(.*)/, @response.body
    @response.body =~ /assoc_handle:(.*)/
    @assoc_handle = $1
    assert_match /expires_in:\d*/, @response.body
  end  

  def assert_check_authentication(args={})
    assert_get_association
    @controller = ServerController.new
    body = {'openid.mode' => 'check_authentication', 'openid.assoc_handle' => @assoc_handle, 'openid.sig' => 'OmmHx9HAfVIwcR1KNNCfmA0M7ec%3D', 'openid.signed' => 'identity,return_to,mode,sreg.email', 'openid.identity' => 'http://quentin.test.host', 'openid.return_to' => 'http://localhost:2000', 'openid.sreg.email' => 'quentin@test.com'}.merge(args)
    post_without_ssl :index, body
    assert_response :success   # Should really be a redirect, but this test will need to be in integration for that to work.
    assert_match /is_valid/, @response.body
  end
end
