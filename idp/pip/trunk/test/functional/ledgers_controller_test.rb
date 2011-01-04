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
require 'ledgers_controller'

# Re-raise errors caught by the controller.
class LedgersController; def rescue_action(e) raise e end; end

class LedgersControllerTest < Test::Unit::TestCase
  fixtures :ledgers, :users

  def setup
    @controller = LedgersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :quentin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    login_as 'quentin'
    get :list

    ledgers = Ledger.find(:all, :conditions => ['user_id = ?', users(:quentin).id], :limit => 10)
    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:ledgers)
  end

end
