# == Schema Information
# Schema version: 27
#
# Table name: property_types
#
#  id           :integer(11)   not null, primary key
#  parent_id    :integer(11)   
#  title        :string(255)   
#  short_name   :string(255)   
#  mime_type    :string(255)   
#  description  :text          
#  created_at   :datetime      
#  updated_at   :datetime      
#  user_id      :integer(11)   
#  is_global    :boolean(1)    
#  control_type :string(255)   default(input_text)
#  format       :string(255)   
#  order_by     :integer(11)   
#

# Determines what kind of properties can exist.
# Acts as a tree.
#--
# TODO DOCUMENTATION: Comment on global vs. personal property types.
class PropertyType < ActiveRecord::Base
  acts_as_tree :order => 'order_by ASC'#:counter_cache => true
  belongs_to :user
  after_create :set_order_by
  has_many :properties, :dependent => :delete_all
  belongs_to  :open_id_mapping

  validates_presence_of :title
  validates_presence_of :short_name
  
  class << self
    # Return all the root nodes of PropertyType trees.
    def roots
      find(:all, :conditions => ['property_types.parent_id IS NULL'], :include => :children)
    end
    
    # Find all global PropertyTypes that do not have children.
    def find_global_leaves
      find_leaf_nodes.to_a.select {|node| node.is_global?}
    end
    
    # Find all PropertyTypes that do not have children.
    def find_leaf_nodes
      find(:all, :conditions => ['property_types.id NOT IN (SELECT DISTINCT parent_id FROM property_types WHERE parent_id != 1) AND property_types.id != 1'])
    end
  
    # Find all root node PropertyTypes that are global or owned by _user_.
    # ====Parameters
    # user:: The User for whom we're finding PropertyTypes.
    def roots_global_or_owned_by(user)
      find(:all, :conditions => ['property_types.parent_id = 1 AND (property_types.is_global = 1 OR property_types.user_id = ?)', user.id], :order => 'property_types.created_at ASC')
    end
  end
  
  # Returns true if the PropertyType is global or owned by _user_.
  # ====Parameters
  # user:: The User for whom we're determining ownership.
  def is_global_or_owned_by?(user)
    self.is_global? || self.user_id == user.id
  end
  
  # Returns true if the PropertyType is not global and is owned by _user_.
  # ====Parameters
  # user:: The User for whom we're determining ownership.
  def is_not_global_and_is_owned_by?(user)
    !self.is_global? && self.user_id == user.id
  end

  private
  def set_order_by
    self.update_attribute(:order_by, self.id)
  end
end
