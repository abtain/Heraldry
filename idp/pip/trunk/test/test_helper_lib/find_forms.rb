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

require 'test/test_helper_lib/ror_spider'
require 'test/test_helper'
require 'pp'

class FindForms < ActionController::IntegrationTest
  include RorSpider

  fixtures :avatars, :ledgers, :profiles, :profiles_properties,
           :properties, :property_types, :trusts, :users
  
  def setup
    super
    setup_ror_spider
    host! 'test.host'
    @forms = {}
  end
           
  def teardown
    super
    teardown_ror_spider
    puts "Forms found by #{ method_name }:"
    pp @forms.keys
  end
  
  def register_form_page( url )
    if url =~ %r{(.*/)\d+$}
      url = $1
    end
    @forms[url] = true
  end
  
  def test_login_then_test
    get '/account/login'
    assert_response :success
    post '/account/login', :login => 'quentin', :password => 'quentin'
    assert session[:user]
    account_landing_uri = '/account/welcome'
    assert_response :redirect
    assert_redirected_to account_landing_uri
    follow_redirect!
    spider account_landing_uri
  end
  
  def test_no_login_just_test
    get '/'
    spider '/'
  end
end
