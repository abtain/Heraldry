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
require 'property_types_controller'

# Re-raise errors caught by the controller.
class PropertyTypesController; def rescue_action(e) raise e end; end

# TODO: Tests for adding & destroying singuler property
#       Tests for updating
class PropertyTypesControllerTest < Test::Unit::TestCase
  fixtures :users, :property_types, :properties

  def setup
    @controller = PropertyTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    login_as 'arthur'
    get :index
  end

  def test_create_category
    login_as 'arthur'
    assert_difference PropertyType, :count, 3 do
      assert_difference Property, :count do
        xml_http_request :post, :create, :type => 'category'
      end
    end
  end

  def test_create_subcategory
    login_as 'arthur'
    assert_difference PropertyType, :count, 2 do
      assert_difference Property, :count do
        xml_http_request :post, :create, :type => 'sub_category', :parent => PropertyType.root.id
      end
    end
  end

  def test_create_property
    login_as 'arthur'

    create_subcategory_with_property_type(PropertyType.root, users(:arthur))
    @sub_category.reload

    assert_difference PropertyType, :count do
      assert_difference Property, :count do
        xml_http_request :post, :create, :type => 'property', :parent => @sub_category.id
      end
    end
  end

  def test_bad_create_type
    login_as 'arthur'
    assert_no_difference PropertyType, :count do
      assert_no_difference Property, :count do
        assert_raise(RuntimeError) { xml_http_request :post, :create, :type => 'bad type', :parent => PropertyType.root.id }
      end
    end
  end

  def test_update_profile
    login_as 'arthur'
    create_category_with_subcategory_and_property_type(users(:arthur))
    xml_http_request :post, :update, :type => 'profile',
                     :property => {@property.id.to_s => 'test value'},
                     :property_title => {@property_type.id.to_s => 'test title'},
                     :category_title => {@category.id.to_s => 'test category title'} 
    [@property, @property_type, @category].each {|p| p.reload }
    assert_equal 'test value', @property.value
    assert_equal 'test title', @property_type.title
    assert_equal 'test category title', @category.title
  end

  def test_update_category
    login_as 'arthur'
    create_category_with_subcategory_and_property_type(users(:arthur))
    xml_http_request :post, :update, :type => 'category', :id => @category.id,
                     :property => {@property.id.to_s => 'test value'},
                     :property_title => {@property_type.id.to_s => 'test title'},
                     :category_title => {@category.id.to_s => 'test category title'} 
    [@property, @property_type, @category].each {|p| p.reload }
    assert_equal 'test value', @property.value
    assert_equal 'test title', @property_type.title
    assert_equal 'test category title', @category.title
  end

  def test_destroy_category
    login_as 'arthur'
    assert_difference PropertyType, :count, 3 do
      create_category_with_subcategory_and_property_type(users(:arthur))
    end
    @category.reload
    
    assert_difference PropertyType, :count, -3 do
      post :destroy, :id => @category.id
    end
  end

  def test_destroy_subcategory
    login_as 'arthur'
    assert_difference PropertyType, :count, 2 do
      parent = PropertyType.find(:first)
      create_subcategory_with_property_type(parent, users(:arthur))
    end
    @sub_category.reload
    
    assert_difference PropertyType, :count, -2 do
      post :destroy, :id => @sub_category.id
    end
  end

  def test_destroy_property
    login_as 'arthur'
    assert_difference PropertyType, :count, 1 do
      parent = PropertyType.find(:first)
      create_property_type(parent, users(:arthur))
    end
    @property_type.reload

    assert_difference PropertyType, :count, -1 do
      assert_difference Property, :count, -1 do
        post :destroy, :id => @property_type.id
        assert_raise(ActiveRecord::RecordNotFound) { PropertyType.find(@property_type.id) }
        assert_raise(ActiveRecord::RecordNotFound) { Property.find(@property.id) }
      end
    end
  end

  def test_cant_destroy_property_belonging_to_someone_else
    login_as 'arthur'
    assert_raise(RuntimeError) do
      assert_no_difference Property, :count do
        post :destroy, :type => 'property', :id => 1
      end
    end
  end
  
private
  def create_category_with_subcategory_and_property_type(user)
    @category       = PropertyType.root.children.create(:title => 'New Category', 
                                                        :short_name => 'new_category', 
                                                        :is_global => false, :user => user)
    create_subcategory_with_property_type(@category, user)
  end

  def create_subcategory_with_property_type(category, user)
    @sub_category   = category.children.create(:title => 'New Sub-Category', 
                                               :short_name => 'new_sub_category', 
                                               :is_global => false, :user => user)
    create_property_type(@sub_category, user)
  end
  
  def create_property_type(sub_category, user)
    @property_type = sub_category.children.create(:title => 'New Property', :short_name => 'new_property', 
                                                  :is_global => false, :user => user)
    @property = user.properties.create(:property_type => @property_type)
  end


end
