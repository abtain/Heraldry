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

class UtilTest < Test::Unit::TestCase
  def setup
    @controller = AccountController.new
  end
  
  def test_get_account_subdomain
    assert_nil subdomain('localhost', 'localhost')
    assert_nil subdomain('eastmedia.com', 'eastmedia.com')
    assert_nil subdomain('www.eastmedia.com', 'www.eastmedia.com')
    assert_nil subdomain('www.eastmedia.com', 'eastmedia.com')
    assert_nil subdomain('bantay.eastmedia.com', 'bantay.eastmedia.com')
    assert_equal 'bob', subdomain('bob.eastmedia.com', 'eastmedia.com')
    assert_equal 'bob', subdomain('bob.localhost', 'localhost')
    assert_equal 'bob', subdomain('bob.bantay.eastmedia.com', 'bantay.eastmedia.com')
    assert_nil subdomain('google.com', 'eastmedia.com')
    assert_nil subdomain('localhost', 'eastmedia.com')
    assert_nil subdomain('64.59.45.37', 'bantay.eastmedia.com')
  end

  def subdomain(request_host, app_host)
    @controller.send(:get_account_subdomain, request_host, app_host)
  end

end