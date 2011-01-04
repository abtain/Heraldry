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

require 'test/test_helper'

class UserIntegrationTest < ActionController::IntegrationTest
  def test_should_create_captcha
    get "/captcha/new"
    do_with_ssl {get "/account/signup"}
    assert_response :success
    assert_tag :tag => 'img', :attributes => {:id => 'captcha_image'}
    assert_not_nil session['captcha_code']
  end 
  
  def test_should_allow_signup
    get "/captcha/new"
    do_with_ssl { get "/account/signup" }
    code = session['captcha_code']
    assert_difference User, :count do
      create_user({}, :captcha => code)
      assert_response 302
    end
  end
  
  def test_allow_login_without_subdomain
    host! 'localhost'
    do_with_ssl { post '/account/login', :login => 'quentin', :password => 'quentin' }
    assert session[:user]
    account_landing_uri = '/account/welcome'
    assert_response :redirect
    assert_redirected_to account_landing_uri
  end
  
  def create_user(user_options = {}, all_options = {})
    do_with_ssl { post "/account/complete_signup", {:user => { :login    => 'quire', 
                                                               :email => 'quire@example.com', 
                                                               :password => 'quire', 
                                                               :password_confirmation => 'quire' }.
                                                   merge(user_options)}.
                                                   merge(all_options) }
  end
  
end
