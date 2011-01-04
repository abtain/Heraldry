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

# == Schema Information
# Schema version: 27
#
# Table name: trusts
#
#  id         :integer(11)   not null, primary key
#  title      :string(255)   
#  expires_at :datetime      
#  created_at :datetime      
#  updated_at :datetime      
#  profile_id :integer(11)   
#  trust_root :string(255)   
#

# Used to establish a trust relationship between a site and a profile.
# Belongs to a Profile.
class Trust < ActiveRecord::Base
  belongs_to :profile
  
  validates_presence_of :profile_id, :trust_root
  validate_on_create :expires_in_future
  validates_uniqueness_of :trust_root, :scope => :profile_id

  # Returns true if the Trust is not expired (It's expiriation date has not passed.)
  def active?
    return true if new_record?
    t = Time.now.utc
    (never_expires? || t < self.expires_at) && (t > self.created_at)
  end

  # Returns true if the Trust has no expiration date.
  def never_expires?
    !self.expires_at
  end
  
private
  def expires_in_future
    t = Time.now.utc
    errors.add_to_base "Expiration must occur in the future" if self.expires_at && (self.expires_at < t)
  end
end
