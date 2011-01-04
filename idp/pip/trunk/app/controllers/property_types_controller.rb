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

class PropertyTypesController < ApplicationController

  # Display the _current_user_'s master profile.
  #
  # The master profile is the set of all properties associated with this user.
  # #add_category, #add_property, #add_sub_category, #destroy_category,
  # #destroy_property, #destroy_sub_category, 
  def index
    current_user.properties.reload
    @global_or_owned_property_types = PropertyType.roots_global_or_owned_by(current_user)
  end

  def create
    case params[:type]
    when 'category'
      create_category_with_subcategory_and_property_type
      render_action = 'create_category'
    when 'sub_category'
      @category       = PropertyType.find(params[:parent])
      create_subcategory_with_property_type(@category)
      render_action = 'create_sub_category'
    when 'property'
      @sub_category = PropertyType.find(params[:parent])
      create_property_type(@sub_category)
      render_action = 'create_property'
    else
      raise 'IncorrectPropertyCreation'
    end
    respond_to do |wants|
      wants.html { redirect_to :action => :index }
      wants.js   { render :action => render_action }
    end
  end

  def update
    update_properties(params[:property])
    update_property_titles(params[:category_title])
    update_property_titles(params[:property_title])
    
    case params[:type]
    when 'profile'
      flash[:notice] = current_user.save ? "Your profile has been updated." : "Your profile could not be updated."
      redirect_to :action => :index
    when 'category'
      @category = PropertyType.find(params[:id])
      render :action => 'update_category'
    end
  end

  def destroy
    @property_type = PropertyType.find(params[:id])
    destroy_property_type(@property_type)
  end
  
private
  def create_category_with_subcategory_and_property_type
    @category       = PropertyType.root.children.create(:title => 'New Category', 
                                                        :short_name => 'new_category', 
                                                        :is_global => false, :user => current_user)
    create_subcategory_with_property_type(@category)
  end

  def create_subcategory_with_property_type(category)
    @sub_category   = category.children.create(:title => 'New Sub-Category', 
                                               :short_name => 'new_sub_category', 
                                               :is_global => false, :user => current_user)
    create_property_type(@sub_category)
  end
  
  def create_property_type(sub_category)
    @property_type = sub_category.children.create(:title => 'New Property', :short_name => 'new_property', 
                                                  :is_global => false, :user => current_user)
    @property = current_user.properties.create(:property_type => @property_type)
  end

  def destroy_property_type(property_type)
    if property_type.is_not_global_and_is_owned_by?(current_user)
      property_type.destroy
      return true
    else
      raise "Property type is not global and/or owned by #{current_user.login}"
    end
  end

  def update_properties(properties)
    properties ||= []
    properties.each do |key, value|
      property = current_user.properties.find_by_id(key.to_i)
      property.update_attribute(:value,value) unless property.nil?
    end
  end

  def update_property_titles(property_titles)
    property_titles ||= []
    property_titles.each do |key, value|
      property_title = PropertyType.find_by_id(key.to_i)
      property_title.update_attribute(:title,value) unless property_title.nil? || !property_title.is_not_global_and_is_owned_by?(current_user)
    end
  end
end
