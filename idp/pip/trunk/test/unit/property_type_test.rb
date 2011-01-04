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

class PropertyTypeTest < Test::Unit::TestCase
  fixtures :property_types

  def test_create_sub_category
    category = create_category
    sub_category = category.children.create(:title => 'MySpace', :short_name => 'myspace')
    assert sub_category.valid?
  end

  def test_create_category
    category = create_category
    assert category.valid?
  end
  
  def test_delete_cascade_parent_to_child
    PropertyType.destroy( 49 )
    assert_raise( ActiveRecord::RecordNotFound ) do
      PropertyType.find( 50 )
    end
  end

  def test_delete_cascade_property_type_to_property
    PropertyType.destroy( 4 )
    assert_raise( ActiveRecord::RecordNotFound ) do
      Property.find( 1 )
    end
  end
  
  protected
  def create_category(options = {})
    PropertyType.create({ :parent_id => 1, :title => 'Social Networks', :short_name => 'social_networks', :description => 'social_networks' }.merge(options))
  end
end
