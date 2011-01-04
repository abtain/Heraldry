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

class ReorderPersonalPropertyTypes < ActiveRecord::Migration
  class PropertyType < ActiveRecord::Base
    acts_as_tree :order => 'order_by ASC'#:counter_cache => true
    belongs_to :user
    after_create :set_order_by
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

    protected
    def set_order_by
      self.update_attribute(:order_by, self.id)
    end
  end
  
  def self.up
    PropertyType.find_by_short_name("full_name").update_attribute(:order_by, 1)
    PropertyType.find_by_short_name("nickname").update_attribute(:order_by, 2)
    PropertyType.find_by_short_name("gender").update_attribute(:order_by, 3)
    PropertyType.find_by_short_name("dob").update_attribute(:order_by, 4)
    PropertyType.find_by_short_name("timezone").update_attribute(:order_by, 5)
    PropertyType.find_by_short_name("language").update_attribute(:order_by, 6)
  end
  
  def self.down
  end
end