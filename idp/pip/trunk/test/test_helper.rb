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

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  include AuthenticatedTestHelper
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  def with_restricted_names(*names)
    APP_CONFIG[:restricted_names] += names
    yield
    APP_CONFIG[:restricted_names].delete_if {|n| names.include?(n)}
  end

  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference,
      object.send(method)
  end

  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end
  
  alias :get_without_ssl :get unless method_defined?(:get_without_ssl)
  alias :post_without_ssl :post unless method_defined?(:post_without_ssl)
  unless APP_CONFIG[:ssl_disabled]
    def get(path, parameters = nil, headers = nil, flash = nil)
      get_without_ssl path, parameters, headers, flash
      assert_response :redirect
      
      @request.env['HTTP_X_FORWARDED_PROTO'] = 'https'
      get_without_ssl path, parameters, headers, flash
      @request.env.delete('HTTP_X_FORWARDED_PROTO')    
    end
  
    def post(path, parameters = nil, headers = nil, flash = nil)
      post_without_ssl path, parameters, headers, flash
      @request.env['HTTP_X_FORWARDED_PROTO'] = 'https'
      post_without_ssl path, parameters, headers, flash
      @request.env.delete('HTTP_X_FORWARDED_PROTO')    
    end
  end
  
  def logger
    RAILS_DEFAULT_LOGGER
  end
end

class ActionController::Integration::Session
  def login_as(login)
    post '/account/login', :login => login, :password => login
    assert request.session[:user]
    assert cookies['user']
    assert redirect?
  end

  def do_with_ssl
    https!
    yield
    https!(false)
  end

  def get_with_basic(url, options = {})
    get url, nil, 'authorization' => "Basic " + 
                                     Base64.encode64("#{options[:login]}:#{options[:login]}").to_s
  end

  def assert_redirected_to(url)
    assert redirect?
    assert_equal url, interpret_uri(headers["location"].first)
  end

  def assert_redirected_to!(url)
    assert_redirected_to(url)
    follow_redirect!
  end

 
end

class ActionController::IntegrationTest
  def post_with_security_integration(path, parameters=nil, headers=nil)
    parameters ||= {}
    get(path, parameters, headers) unless request
    parameters.update(:session_id_validation => Digest::MD5.hexdigest(session.session_id)) if parameters.respond_to?(:update)
    post_without_security_integration(path, parameters, headers)
  end

  unless instance_methods.include?("post_without_security_integration")
    alias_method :post_without_security_integration, :post
    alias_method :post, :post_with_security_integration
  end
end
 
module OpenIdTestMethods
  def create_checkid(args={})
    {"openid.return_to"=>"http://localhost:2000/complete", 
      "openid.mode"=>"checkid_setup", 
      "openid.identity"=>"http://test.host/user/quentin", 
      "openid.trust_root"=>"http://localhost:2000/", 
      "openid.assoc_handle"=>"{HMAC-SHA1}{44327c5d}{EVAnng==}"}.merge(args)
  end
  
  def create_checkid_query_string(args = {})
    hash = create_checkid(args)
    elements = []
    query_string = ""

    only_keys ||= hash.keys
    
    only_keys.each do |key|
      value = hash[key] 
      key = CGI.escape key.to_s
      if value.class == Array
        key <<  '[]'
      else
        value = [ value ]
      end
      value.each { |val| elements << "#{key}=#{CGI.escape(val.to_s)}" }
    end
    
    query_string << (elements.join("&")) unless elements.empty?
    query_string
  end
end
