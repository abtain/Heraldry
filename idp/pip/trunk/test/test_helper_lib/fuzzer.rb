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

class Fuzzer < ActionController::IntegrationTest
  include RorSpider

  fixtures :avatars, :ledgers, :profiles, :profiles_properties,
           :property_types, :trusts, :users

  def setup
    super
    setup_ror_spider
    host! 'test.host'
    @numeric_id_uris = {}
  end
           
  def teardown
    super
    teardown_ror_spider
  end
  
  def check_generated_page( next_link )
    if next_link.uri =~ %r{^(.*/)\d+$}
      @numeric_id_uris[$1] = true
    end
  end
  
  def assert_bad_uri( bad_uri )
    get bad_uri
    assert_equal(
      "500", @response.code, "#{ bad_uri } returned code #{ @response.code }" 
    )
  end
  
  def fuzz
    @numeric_id_uris.keys.each do |numeric_id_uri|
      5.times do
        assert_bad_uri "#{ numeric_id_uri }#{ rand( 99 ) + 99 }"
      end
      assert_bad_uri numeric_id_uri
      chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz !@#$%^&*()'
      char_array = chars.split //
      5.times do
        size = rand( 10 ) + 1
        id = ''
        size.times do id << char_array[rand(char_array.size)]; end
        id = CGI.escape id
        assert_bad_uri "#{ numeric_id_uri }#{ id }"
      end
    end
  end

  def test_login_then_spider
    get '/account/login'
    assert_response :success
    post '/account/login', :login => 'quentin', :password => 'quentin'
    assert session[:user]
    account_landing_uri = '/account/welcome'
    assert_response :redirect
    assert_redirected_to account_landing_uri
    follow_redirect!
    spider account_landing_uri
    fuzz
  end
  
  def test_no_login_just_spider
    get '/'
    spider '/'
    fuzz
  end
end
