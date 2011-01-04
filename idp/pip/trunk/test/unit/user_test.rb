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

class UserTest < Test::Unit::TestCase
  fixtures :users, :ledgers, :avatars, :properties, :property_types

  def test_should_create_user
    assert_difference User, :count do
      assert create_user.valid?
    end
  end
  
  def test_should_be_case_insensitive_on_login_comparison
    assert_no_difference User, :count do
      u = create_user(:login => users(:quentin).login.upcase)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_not_allow_login_with_underscore
    assert_no_difference User, :count do
      u = create_user(:login => 'quentin_jones')
      assert u.errors.on(:login)
    end
  end

  def test_should_allow_login_with_dash
    u = create_user(:login => 'quentin-jones')
    assert !u.errors.on(:login)
  end

  def test_should_allow_login_with_two_dots
    u = create_user(:login => 'quentin.mark.jones')
    assert u.valid?, u.errors.full_messages.join("\n")
  end

  def test_should_require_letters_between_dots
    assert create_user(:login => 'quentin..jones').errors.on(:login)
  end

  def test_should_not_allow_login_with_three_dots
    assert create_user(:login => 'quentin.mark.jones.toomuch').errors.on(:login)
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end
 
  def test_should_ensure_email_is_properly_formatted
    assert_no_difference User, :count do
      u = create_user(:email => 'bobboberson')
      assert u.errors.on(:email)
    end
  end

  def test_should_be_case_insensitive_on_email_comparison
    assert_no_difference User, :count do
      u = create_user(:email => users(:quentin).email.upcase)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'quentin')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'quentin')
  end
  
  def test_login_should_be_case_insensitive_on_authentication
    assert_equal users(:quentin), User.authenticate('QUENTIN', 'quentin')
  end

  def test_last_login
    assert_equal 2, users(:quentin).ledgers.count
    assert ledgers(:login1)
    assert_equal ledgers(:login1).created_at.to_formatted_s(:short_date), users(:quentin).last_login
  end
  
  def test_only_one_login
    Ledger.destroy(3)
    assert_equal 1, users(:quentin).ledgers.count
    assert ledgers(:login2)
    assert_equal ledgers(:login2).created_at.to_formatted_s(:short_date), users(:quentin).last_login
  end
  
  def test_destroy_user
    assert_difference User, :count, -1 do
      User.destroy 1
    end
  end
  
  def test_activate_user
    assert_nil users(:arthur).activated_at
    assert users(:arthur).activation_code
    
    users(:arthur).activate
    users(:arthur).reload
    
    assert users(:arthur).activated_at
    assert_nil users(:arthur).activation_code
  end
  
  def test_attributes_are_protected
    users(:quentin).update_attributes(:crypted_password => 'bob', :updated_at => (ua = 2.days.ago),
                                      :created_at => (ca = Time.now), :salt => 'salty', :identity_url => 'bob',
                                      :activation_code => 'activate', :activated_at => (aa = Time.now))
    assert_not_equal 'bob', users(:quentin).crypted_password
    assert_not_equal ua, users(:quentin).updated_at
    assert_not_equal ca, users(:quentin).created_at
    assert_not_equal 'salty', users(:quentin).salt
    assert_not_equal 'bob', users(:quentin).identity_url
    assert_not_equal 'activate', users(:quentin).activation_code
    assert_not_equal aa, users(:quentin).activated_at
  end
  
  def test_get_property_by_property_name
    assert !users(:quentin).properties.delete_if{|p| p.property_type.short_name != 'nickname'}.empty?
    assert_not_nil users(:quentin).properties.value_for_nickname
    assert_nil users(:quentin).properties.value_for_bad_bad_property
    assert_raises(NoMethodError) { assert_nil users(:quentin).properties.bad_bad_property }
  end
  
  protected
  def create_user(options = {})
    User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end
end
