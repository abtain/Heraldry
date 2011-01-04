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

class PropertyType < ActiveRecord::Base
  acts_as_tree
  belongs_to :user
  has_many :properties, :dependent => :delete_all

  DIX     = 'dix://sxip.net/'
  OpenID  = 'openid.sreg'

  class << self
    def roots
      find(:all, :conditions => ['property_types.parent_id IS NULL'], :include => :children)
    end

    def find_global_leaves
      find_leaf_nodes.to_a.select {|node| node.is_global?}
    end

    def find_children(property_type)
      find(:all, :conditions => ['parent_id = ?', property_type.id])
    end

    def find_leaf_nodes
      find(:all, :conditions => ['property_types.id NOT IN (SELECT DISTINCT parent_id FROM property_types WHERE parent_id != 1) AND property_types.id != 1'])
    end

    def roots_global_or_owned_by(user)
      find(:all, :conditions => ['property_types.parent_id = 1 AND (property_types.is_global = 1 OR property_types.user_id = ?)', user.id], :order => 'property_types.created_at ASC')
    end
  end

  def is_global_or_owned_by?(user)
    self.is_global? || self.user_id == user.id
  end

  def is_not_global_and_is_owned_by?(user)
    !self.is_global? && self.user_id == user.id
  end

  def has_grandchildren?
    self.children.any? do |child|
      child.has_children?
    end
  end

  validates_presence_of :title
  validates_presence_of :short_name
end

class AddFullnamePropertyType < ActiveRecord::Migration
  def self.up
    p = PropertyType.find_by_short_name("personal")
    if p
      fullname = p.children.create(:is_global => true, :title => "Full Name", :mime_type => "string",
                            :description => "Full Name", :short_name => "full_name", :control_type => "input_text")
      User.find_all.map do |u| 
        u.properties << Property.new(:property_type => fullname, 
                                     :value => [u.properties.value_for_first_name.to_s, 
                                                u.properties.value_for_middle_name.to_s,
                                                u.properties.value_for_last_name.to_s].join(' '))
        u.save
      end
      ["first_name", "middle_name", "last_name"].each do |short_name|
        property_type = PropertyType.find_by_short_name(short_name)
        property_type.destroy if property_type
      end
    else
      raise "No Personal Property Type"
    end
  end
  
  def self.down    
    PropertyType.find_by_short_name("full_name").destroy
  end
end