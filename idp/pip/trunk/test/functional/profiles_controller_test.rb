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
require 'profiles_controller'

# Re-raise errors caught by the controller.
class ProfilesController; def rescue_action(e) raise e end; end

class ProfilesControllerTest < Test::Unit::TestCase
  fixtures :profiles, :users

  def setup
    @controller = ProfilesController.new
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
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:profiles)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:profile)
    assert assigns(:profile).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:profile)
  end

  def test_create
    assert_difference Profile, :count do 
      assert_difference users(:quentin).profiles, :count do
        post :create, :profile => { :title => 'Evil Villain' }

        assert_response :redirect
        assert_redirected_to :action => 'list'
        users(:quentin).reload
      end
    end
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:profile)
    assert assigns(:profile).valid?
  end

  def test_update
    post :update, :profile => {:title => 'family', :description => 'for the folks' }, :property => nil, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    assert_difference Profile, :count, -1 do
      post :destroy, :id => 1
      assert_response :redirect
      assert_redirected_to :action => 'list'
    end
  end

  def test_destroy_with_ajax
    assert_difference Profile, :count, -1 do
      xhr :post, :destroy, :id => 1
      assert_response :success
      assert_match /drop_out/, @response.body
    end
  end
end
