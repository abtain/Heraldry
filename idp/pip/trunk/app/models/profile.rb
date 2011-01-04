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
# Table name: profiles
#
#  id          :integer(11)   not null, primary key
#  user_id     :integer(11)   
#  title       :string(255)   
#  description :text          
#  created_at  :datetime      
#  updated_at  :datetime      
#

# Stores a profile for a given user.
# Profiles are subsets of a user's information that allow for easy
# association of that data with a specific site.
class Profile < ActiveRecord::Base
  attr_protected :user_id, :created_at, :updated_at
  
  belongs_to :user
  has_many :trusts
  has_and_belongs_to_many :properties do
    # Defined for profile.properties
    # Find a property by its property type.
    # ====Parameters
    # property_type:: Object of class PropertyType
    def find_by_property_type(property_type)
      self.to_a.detect { |p| p.property_type_id == property_type.id }
    end
    
    # Defined for profile.properties
    # Use value_for_[short_name] to find the value of a property given its PropertyType short_name.
    # For example: profile.properties.value_for_nickname would return the value for the property that
    # has a PropertyType with a shortname of nickname.
    # *args:: String that matches a PropertyType.short_name
    def method_missing(sym, *args)
      return super unless sym.to_s =~ /value_for_(\w*)/
      return nil unless property_type = PropertyType.find_by_short_name($1)
      (prop = self.find_by_property_type(property_type)) ? (prop.value || '') : nil
    end
  end
  
  validates_presence_of :user_id, :title
  validates_uniqueness_of :title, :scope => :user_id

  # Returns true if the profile has all the properties of the property types listed in props.
  # ====Parameters
  # *props:: Array of strings that match a PropertyType.short_name
  def has_properties?(*props)
    fields = self.properties.map{|p| p.property_type.short_name}
    fields.superset?(props.flatten)
  end
  
  # Add properties to the profile.
  # ====Parameters
  # properties:: Array of Property ids.
  def add_properties(properties)
    self.properties.clear
    return nil unless properties
    properties.each do |key|
      self.properties << Property.find(key.to_i)
    end
  end
end
