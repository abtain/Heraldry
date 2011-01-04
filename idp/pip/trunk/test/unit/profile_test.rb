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

class ProfileTest < Test::Unit::TestCase
  fixtures :users, :profiles, :properties, :property_types,
           :profiles_properties
  
  def test_create
    profile = create_profile(:user => users(:quentin))
    assert profile.valid?
  end
  
  def test_create_profile_with_properties
    assert true
  end
  
  def test_create_allows_same_name_across_two_users
    start_profile_count = Profile.count
    create_profile( :user => users(:quentin), :title => 'same title' )
    create_profile( :user => users(:arthur), :title => 'same title' )
    assert_equal( 2, Profile.count - start_profile_count )
  end
  
  def test_attributes_are_protected
    profile = Profile.find_first
    profile.update_attributes(:user_id => 100, :created_at => (ca = 2.days.from_now), :updated_at => (ua = 2.days.from_now))
    assert_not_equal 100, profile.user_id
    assert_not_equal ca, profile.created_at
    assert_not_equal ua, profile.updated_at
  end

  protected
  def create_profile(options={})
    Profile.create({:title => 'Blogs', :description => 'For blog commenting'}.merge(options))
  end
end
