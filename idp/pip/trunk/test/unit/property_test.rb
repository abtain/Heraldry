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

class PropertyTest < Test::Unit::TestCase
  fixtures :users, :properties, :property_types

  def test_create_property
    property = create_property(:user => users(:quentin), :property_type => property_types(:property_type_40), :value => 'Francois')
    assert property.valid?
  end
  
  def test_create_property_without_property_type
    property = create_property(:user => users(:quentin))
    assert property.errors.on(:property_type_id)
  end
  
  def test_should_not_allow_duplicate_property_types
    user          = users(:quentin)
    middle_name   = property_types(:property_type_40)
    assert user.properties.create(:property_type => middle_name).valid?
    assert !user.properties.create(:property_type => middle_name).valid?
  end
  
  def test_create_property_with_existing_property_type
    property_type = property_types(:property_type_40)
    property = create_property(:user => users(:quentin), :property_type => property_type)
    assert property.valid?
  end
  
  def test_create_property_with_new_property_type
    property_type = PropertyType.create(:title => 'Social Network', :short_name => 'social_networks', :parent_id => 1)
    property = create_property(:user => users(:quentin), :property_type => property_type)
    assert property.valid?
  end
  
  def test_update_date_select_with_date_hash
    property = properties(:openid5)
    hash = HashWithIndifferentAccess.new(:year => '2006', :day => '01', :month => '06')
    assert_equal 'date_select', property.property_type.control_type
    assert property.update_attribute(:value, hash)
    property.reload
    assert_equal Date.strptime('2006-06-01', '%Y-%m-%d'), property.value
  end

  def test_update_date_select_with_no_year
    property = properties(:openid5)
    assert property.update_attribute(:value, {:year => '', :day => '01', :month => '06'})
    property.reload
    assert_nil property.value
  end
   
  def test_update_date_select_with_nil
    property = properties(:openid5)
    assert property.update_attribute(:value, nil)
    property.reload
    assert_nil property.value
  end
  
  def test_update_date_select_with_empty_hash
    property = properties(:openid5)
    assert property.update_attribute(:value, {})
    property.reload
    assert_nil property.value
  end
  
  protected
  def create_property(options={})
    Property.create({ :value => '' }.merge(options))
  end
end
