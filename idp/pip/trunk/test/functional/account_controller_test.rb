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
require 'account_controller'
require File.dirname(__FILE__) + '/../../lib/yadis_handler/lib/yadis_handler'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  include OpenIdTestMethods  
  
  fixtures :users, :avatars, :db_files, :property_types, :properties

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @emails = ActionMailer::Base.deliveries 
    @emails.clear
  end

  def test_should_show_identity_url
    login_as 'quentin'
    get :welcome
    assert_match(%r[Identity URL: <span class="highlighted">quentin.test.host</span>], @response.body)
  end

  def test_should_show_login_as_identity_url_with_restricted_login
    login_as 'two_dots'
    with_restricted_names('turner') { get :welcome }
    assert_match(%r[Identity URL: <span class="highlighted">linda.joe.turner</span>], @response.body)
  end

  def test_should_return_yadis_document
    @request.host = 'quentin.test.host'
    @request.env['HTTP_ACCEPT'] = 'application/xrds+xml'
    get :index
    assert_response :success
    assert_match %r[<XRD>], @response.body
  end

  def test_welcome_should_contain_xrds_location_header
    get_quentin_identity_url
    assert_xrds_location_header_for('quentin')
  end

  def test_welcome_should_convert_xrds_location_header_with_two_dot_username
    get_linda_restricted_identity_url
    assert_xrds_location_header_for('linda.joe.turner')
  end

  def test_welcome_should_contain_yadis_location_header
    get_quentin_identity_url
    assert_yadis_location_header_for('quentin')
  end

  def test_welcome_should_convert_yadis_location_header_with_two_dot_username
    get_linda_restricted_identity_url
    assert_yadis_location_header_for('linda.joe.turner')
  end

  def test_welcome_should_contain_openid_info
    get_quentin_identity_url
    assert_openid_server_tag
  end

  def test_welcome_should_contain_xrds_location
    get_quentin_identity_url
    assert_xrds_location_for('quentin')
  end

  def test_welcome_should_convert_xrds_location_for_two_dot_username
    get_linda_identity_url
    assert_xrds_location_for('linda.joe.turner')
  end

  def test_welcome_should_convert_xrds_location_for_two_dot_username_and_restricted
    get_linda_restricted_identity_url
    assert_xrds_location_for('linda.joe.turner')
  end

  def test_welcome_should_convert_yadis_location_for_two_dot_username_and_restricted
    get_linda_restricted_identity_url
    assert_yadis_location_for('linda.joe.turner')
  end

  def test_welcome_should_contain_yadis_location
    get_quentin_identity_url
    assert_yadis_location_for('quentin')
  end

  def test_welcome_should_convert_yadis_location_for_two_dot_username
    get_linda_identity_url
    assert_yadis_location_for('linda.joe.turner')
  end

  def test_should_return_yadis_document_with_two_dot_login
    @request.host = 'linda.joe.turner.test.host'
    @request.env['HTTP_ACCEPT'] = 'application/xrds+xml'
    get :index
    assert_response :success
    assert_match %r[<XRD>], @response.body
  end

  def test_should_return_yadis_document_with_two_dot_login_with_restricted
    @request.host = 'linda.joe.turner'
    @request.env['HTTP_ACCEPT'] = 'application/xrds+xml'
    with_restricted_names('turner') { get :index }
    assert_response :success
    assert_match %r[<XRD>], @response.body
  end

  def test_should_login_and_redirect
    post :login, :login => 'quentin', :password => 'quentin'
    assert_response :redirect
    assert session[:user]
  end

  def test_should_login_and_redirect_with_two_dot_username
    post :login, :login => 'linda.joe.turner', :password => 'linda'
    assert session[:user]
  end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'quentin', :password => 'bad password'
    assert_response :success
    assert_nil session[:user]
  end

  def test_should_fail_login_and_show_flash_once
    post :login, :login => 'quentin', :password => 'bad password'
    assert_response :success
    assert_template 'login'
    assert_nil flash[:notice]
  end

  def test_should_redirect_with_proper_protocol_on_openid_login
    post :login, :login => 'quentin', :password => 'quentin',
                 :previous_protocol => 'http://', :return_to_query => 'openid.mode=checkid_setup'
    assert_response :redirect
    assert_match(%r[http://], @response.redirected_to)

    post :login, :login => 'quentin', :password => 'quentin',
                 :previous_protocol => 'https://', :return_to_query => 'openid.mode=checkid_setup'
    assert_response :redirect
    assert_match(%r[https://], @response.redirected_to)
  end

  def test_prepopulation_of_login_field
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://test.host/user/quentin')
    assert_match( /value="quentin"/, @response.body)
    
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://arthur.test.host/')
    assert_match( /value="arthur"/, @response.body)
  end
  
  def test_prepopulation_of_login_field_mixed_case
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://test.host/user/mixedcase')
    assert_match( /value="MixedCase"/, @response.body)
    
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://mixedcase.test.host/')
    assert_match( /value="MixedCase"/, @response.body)
  end

  def test_should_prepopulate_login_field_with_dotted_login
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://test.host/user/linda_joe_turner')
    assert_match( /value="linda\.joe\.turner"/, @response.body)
    
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://linda.joe.turner.test.host/')
    assert_match( /value="linda\.joe\.turner"/, @response.body)
  end

  def test_should_prepopulate_login_field_with_dotted_login_when_name_is_restricted
    with_restricted_names('turner') do
      get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://linda.joe.turner/user/linda_joe_turner')
    end
    assert_match( /value="linda\.joe\.turner"/, @response.body)
    
    with_restricted_names('turner') do
      get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://linda.joe.turner/')
    end
    assert_match( /value="linda\.joe\.turner"/, @response.body)
  end

  def test_prepopulation_of_login_field_no_user
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://test.host/user/doesnotexist')
    assert_match( /value="doesnotexist"/, @response.body)
    
    get :login, :return_to_query => create_checkid_query_string("openid.identity" => 'http://doesnotexist.test.host/')
    assert_match( /value="doesnotexist"/, @response.body)
  end

  def test_should_require_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
      assert_template 'signup'
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference User, :count do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
      assert_template 'signup'
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference User, :count do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
      assert_template 'signup'
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference User, :count do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
      assert_template 'signup'
    end
  end
  
  def test_dont_signup_with_invalid_login
    [ 'spaced login', 'login!', 'www' ].each do |invalid_login|
      assert_no_difference User, :count do
        create_user( :login => invalid_login )
        assert assigns( :user ).errors.on( :login )
        assert_response :success
        assert_template 'signup'
      end
    end
  end

  def test_should_not_allow_restricted_dot_logins
    APP_CONFIG[:restricted_names] << 'jones'
    create_user(:login => 'quentin.mark.jones')
    assert assigns(:user).errors.on(:login)
  end

  def test_should_allow_non_restricted_dot_logins
    APP_CONFIG[:restricted_names].delete('jones')
    create_user(:login => 'quentin.mark.jones')
    assert_valid assigns(:user)
  end

  def test_should_logout
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  def test_should_show_flash_on_edit
    login_as :arthur
    post :edit, :user => {:password => 'newone', :password_confirmation => 'newone'}
    assert_response :success
    assert_match(/were updated successfully\./, @response.body)
  end
  
  def test_should_clear_password_confirmation_on_edit
    login_as :arthur
    post :edit, :user => {:password => 'newone', :password_confirmation => 'newone'}
    assert_response :success
    assert_nil assigns(:current_user).password
    assert_nil assigns(:current_user).password_confirmation
  end
  
  def test_should_show_flash_when_unable_to_update
    login_as :arthur
    post :edit, :user => {:password => 'newone', :password_confirmation => 'bad'}
    assert_response :success
    assert_match(/could not be updated\./, @response.body)
  end

  def test_should_activate_user
    assert_equal users(:arthur), User.authenticate('arthur', 'arthur')
  end
  
  def test_should_send_activation_email_after_signup
    create_user
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Please activate your new account/)
    assert(@emails.first.body    =~ /Username: quire/)
    assert(@emails.first.body    =~ /account\/activate\/#{assigns(:user).activation_code}/)
    assert_not_nil assigns(:user).activation_code
  end
  
  def test_sent_to_index_with_nil_activation_code_on_activate
    login_as 'quentin'
    get :activate
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'index'
    assert_nil assigns('user')
  end

  def test_should_resend_activation_email
    login_as 'arthur'
    post :resend_confirmation
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Please activate your new account/)
    assert(@emails.first.body    =~ /Username: arthur/)
    assert(@emails.first.body    =~ /account\/activate\/#{users(:arthur).activation_code}/)
    assert_template 'index'
  end

  def test_should_activate_user_with_activation_code
    login_as 'arthur'
    assert_equal 'arthurscode', users(:arthur).activation_code
    assert_nil users(:arthur).activated_at

    post :activate, :id => users(:arthur).activation_code
    users(:arthur).reload
    
    assert_nil users(:arthur).activation_code
    assert users(:arthur).activated_at
    
    assert_equal 1, @emails.length
    assert_match(/Your account has been activated!/, @emails.first.subject)
    assert_match(%r[http://test.host/], @emails.first.body)
  end

  def test_should_show_confirmation_form
    login_as 'quentin'
    get :resend_confirmation
    assert_equal 0, @emails.length
    assert_template 'resend_confirmation'
  end

  def test_should_send_no_activation_email_for_activated_users
    login_as 'quentin'
    post :resend_confirmation
    assert_equal 0, @emails.length
    assert_template 'resend_confirmation'
  end

  def test_should_send_password_reset_email
    post_without_ssl :forgot_password, :email => users(:quentin).email
    assert_nil users(:quentin).activation_code
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Reset your password/)
    assert(@emails.first.body    =~ /quentin,/)
    assert(@emails.first.body    =~ /account\/reset_password\/#{users(:quentin).reload.activation_code}/)
    assert users(:quentin).activation_code
    assert_template 'index'
    assert_nil flash[:notice]
  end
  
  def test_should_show_message_when_unable_to_send_password_reset
    post_without_ssl :forgot_password, :email => 'not_a_real_email'
    assert_match(/We couldn't find your account\./, @response.body)
  end

  # TODO: Change this to an integration test
#  def test_sending_forgot_password_email_should_not_cause_confirmation_flash_to_show
#    login_as 'quentin'
#    post_without_ssl :forgot_password, :email => users(:quentin).email
#    get :profile
#    assert_no_match(/You have not yet verified your e-mail address\./, @response.body)
#  end

  def test_should_show_password_reset_form
    get_without_ssl :forgot_password
    assert_equal 0, @emails.length
    assert_template 'forgot_password'
  end

  def test_should_show_change_password_form
    login_as 'quentin'
    get :reset_password, :id => users(:arthur).activation_code
    assert_equal 0, @emails.length
    assert_template 'reset_password'
  end
  
  def test_should_not_update_password_with_nil_activation_code
    login_as 'quentin'
    post :reset_password, :user => { :password => 'foobar', :password_confirmation => 'foobar' }
    assert_response :success
    assert_nil assigns('user')
  end
  
  def test_should_update_password
    login_as 'arthur'
    
    # Sanity test
    assert_not_nil users(:arthur).activation_code
    assert_nil users(:arthur).activated_at
    
    post :reset_password, :id => users(:arthur).activation_code, :user => { :password => 'foobar', :password_confirmation => 'foobar' }
    users(:arthur).reload

    assert_redirected_to :action => 'welcome'
    assert_equal users(:arthur), User.authenticate('arthur', 'foobar')
    assert_nil users(:arthur).activation_code
    assert_not_nil users(:arthur).activated_at
  end

  def test_should_fail_bad_captcha_code
    get :signup
    assert_no_difference User, :count do
      create_user({}, :captcha => 'bad_captcha')
      assert_response :success
      assert_template 'signup'
      assert_not_nil assigns['captcha_error']
    end
  end

  def test_should_report_all_errors_on_bad_captcha
    assert_no_difference User, :count do
      create_user({:password => 'one', :password_confirmation => 'two'}, :captcha => 'bad_captcha')
      assert assigns['user'].errors.size > 1
    end
  end

  def test_yadis_get_document
    @request.host = 'quentin.test.host'
    @request.env.merge!('HTTP_ACCEPT' => 'application/xrds+xml')
    get_without_ssl :index
    assert_yadis_document
  end

  def test_authorization_for_mixed_case_subdomain
    login_as 'quentin'
    @request.host = 'Quentin.test.host'
    get :welcome
    assert_response :success
  end

  def test_logged_in_and_navigating_to_other_users_subdomain
    login_as 'quentin'
    @request.host = 'arthur.test.host'
    get :welcome
    assert_response :redirect
    assert_not_nil flash[:notice]
  end

  def test_logging_in_to_wrong_subdomain
    @request.host = 'arthur.test.host'
    post :login, :login => 'quentin', :password => 'quentin'
    assert_response :success
    assert_match(/Bad username or password for identity url:/i, @response.body)
  end

  protected
  def create_user(user_options = {}, all_options = {})
    post :complete_signup, {:user => { :login    => 'quire', :email => 'quire@example.com', 
                                     :password => 'quire', :password_confirmation => 'quire' }.
                                    merge(user_options)}.
                                    merge(all_options)
  end
  
  @@mongrel_yadis_test_dir = File.dirname(__FILE__) + '/../../lib/yadis_handler/test'
  
  def assert_yadis_document
    assert_match %r[application/xrds\+xml], @response.headers['Content-Type']
    xml_body = @response.body

    assert_match %r[<Type>http://openid.net/signon/1.0</Type>], xml_body
    assert_match %r[<URI>http://test.host/server</URI>], xml_body
    assert_match %r[<Type>http://openid.net/signon/1.1</Type>], xml_body
    
    File.open('temp.xml', 'w') { |f| f << xml_body }
    xmllint_result = `xmllint --schema #{ @@mongrel_yadis_test_dir }/xrds_schema.xml temp.xml 2>&1`
    assert_match /temp.xml validates/, xmllint_result

    xml = REXML::Document.new(xml_body)
    xrd = xml.root.elements[1]
    xrd.add_attributes('xmlns' => 'xri://$xrd*($v*2.0)', 
                       'xmlns:openid' => 'http://openid.net/xmlns/1.0')
    File.open('temp.xml', 'w') { |f| f << xrd.to_s }
    xmllint_result = `xmllint --schema #{ @@mongrel_yadis_test_dir }/xrd_schema.xml temp.xml 2>&1`
    assert_match /temp.xml validates/, xmllint_result
  end

  def get_identity_url_for(domain)
    @request.host = domain
    get :index
  end

  def get_quentin_identity_url
    get_identity_url_for('quentin.test.host')
  end

  def get_linda_identity_url
    get_identity_url_for('linda.joe.turner.test.host')
  end

  def get_linda_restricted_identity_url
    with_restricted_names('turner') { get_identity_url_for('linda.joe.turner') }
  end
  
  def assert_openid_server_tag
    assert_match %[<link rel="openid\.server" href="http://test.host/server"], @response.body
  end

  def assert_xrds_location_for(name)
    name = name.gsub(/\./, '_')
    assert_match %r[<meta http-equiv="X-XRDS-Location" content="http://test.host/user/#{name}/yadis"],
                 @response.body
  end

  def assert_xrds_location_header_for(name)
    name = name.gsub(/\./, '_')
    assert_equal "http://test.host/user/#{name}/yadis", @response.headers['X-XRDS-Location']
  end

  def assert_yadis_location_header_for(name)
    name = name.gsub(/\./, '_')
    assert_equal "http://test.host/user/#{name}/yadis", @response.headers['X-YADIS-Location']
  end

  def assert_yadis_location_for(name)
    name = name.gsub(/\./, '_')
    assert_match %r[<meta http-equiv="X-YADIS-Location" content="http://test.host/user/#{name}/yadis"],
                 @response.body
  end

end
