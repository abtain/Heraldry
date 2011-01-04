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
require 'trusts_controller'

# Re-raise errors caught by the controller.
class TrustsController; def rescue_action(e) raise e end; end

class TrustsControllerTest < Test::Unit::TestCase
  fixtures :users, :trusts, :profiles
  def setup
    @controller = TrustsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :quentin
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_destroy
    login_as 'quentin'
    assert_difference Trust, :count, -1 do
      get :destroy, :id => 1
      assert_response :redirect
      assert_redirected_to :action => 'list'
    end
  end
  
  def test_sort
    login_as 'quentin'
    sorted_trusts = users(:quentin).trusts.find(:all, :include => :profile, :limit => 10, :order => 'trusts.title asc')
    get :list
    assert_response :success
    assert_not_equal sorted_trusts.map{|t| t.id}, assigns(:trusts).map{|t| t.id}
    get :list, :order_by => 'trusts.title', :order => 'asc'
    assert_response :success
    sorted_trusts = users(:quentin).trusts.find(:all, :include => :profile, :limit => 10, :order => 'trusts.title asc')
    assert_equal sorted_trusts.map{|t| t.id}, assigns(:trusts).map{|t| t.id}
  end
end
