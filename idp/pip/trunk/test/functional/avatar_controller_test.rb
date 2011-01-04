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
require 'avatar_controller'

# Re-raise errors caught by the controller.
class AvatarController; def rescue_action(e) raise e end; end

class AvatarControllerTest < Test::Unit::TestCase
  fixtures :users, :avatars, :db_files

  def setup
    @controller = AvatarController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_upload_avatar
    login_as :arthur
    assert_difference DbFile, :count do
      assert_difference Avatar, :count do
        post :create, :user => { :avatar_data => fixture_file_upload('avatars/casshern.jpg', 'image/jpeg') }
        assert_redirected_to :action => 'congratulations'
        assert flash[:notice]
        assert users(:arthur).reload.avatar
        assert users(:arthur).reload.avatar.db_file
      end
    end
  end

  def test_should_show_avatar
    login_as :quentin
    @request.session[:secret_code] = 'I am a secret code.'
    get :show, :secret_code => @request.session[:secret_code]
    assert_response :success
    assert_not_nil assigns['user']
    assert assigns['user'].respond_to?(:data)
  end
  
  def test_should_not_show_avatar_without_secret_code
    login_as :quentin
    get :show
    assert_response :success
    assert_equal 'No access', @response.body
    assert_nil assigns['user']
  end

  def test_should_not_allow_bad_avatar
    login_as :arthur
    assert_no_difference DbFile, :count do
      assert_no_difference Avatar, :count do
        post :create, :user => { :avatar_data => fixture_file_upload('avatars/bad_avatar.txt', 'text/plain') }
        assert_redirected_to :action => 'congratulations'
        assert flash[:error]
        assert_nil users(:arthur).reload.avatar
      end
    end    
  end
  
  def test_should_show_error_when_uploading_nothing_for_avatar
    login_as :arthur
    assert_no_difference DbFile, :count do
      assert_no_difference Avatar, :count do
        post :create, :user => {:avatar_data => StringIO.new}
        assert_redirected_to :action => 'congratulations'
        assert flash[:error]
        assert_nil users(:arthur).reload.avatar
      end
    end
  end
  
end
