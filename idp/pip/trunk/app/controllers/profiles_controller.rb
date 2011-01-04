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

# == About
# ProfilesController is responsible for displaying trust profiles
# to the user.
#
# == Requirements
# SSL and login are required on all actions.
#
# Destroy, create, and update may only be accessed via a post method.
class ProfilesController < ApplicationController
  before_filter :login_required
  before_filter :find_profile, :only => [:show, :edit, :update, :destroy, :members]
  before_filter :find_global_or_owned_property_types, :only => [:new, :edit, :create, :update]
  
  # Alias for list.
  def index
    list
    render :action => 'list' unless performed?
  end

  # GET should only be used for operations which are 'safe', or read-only. So require
  # post for all actions which change state.
  #  
  # http://www.w3.org/2001/tag/doc/whenToUseGet.html
  verify :method=>:post, :only=>[:destroy, :create, :update],
         :redirect_to=> {:action=>:list}

  # Show all profiles for _current_user_, sorted by the order they were created.
  # ====params
  # page:: Number indicating the current page.
  def list
    @profile_pages, @profiles = paginate_collection current_user.profiles, {:per_page => 10, :order_by => 'created_at DESC', :page => params[:page]}
  end

  # Display a form for the creation of a new profile.
  def new
    @profile ||= current_user.profiles.new
    current_user.properties.reload
  end
  
  # Edit an existing profile.
  # ====params
  # id:: Profile#id
  def edit
    current_user.properties.reload
  end
  
  # Show the Trusts that belong to this Profile
  # ====params
  # id:: The Profile#id
  def members
    @profile = current_user.profiles.find(params[:id], :include => :trusts)
  end

  # Create a new profile.  May only be accessed with a post request.
  # ====params
  # profile:: Array containing properties for the Profile.
  # property:: Array of Property#id's to be associated with the Profile.
  #--
  # TODO: Do we use ajax saving here?  Can / should it be removed?
  def create
    @profile = current_user.profiles.create(params[:profile])
    @profile.add_properties(params[:property])

    if @profile.save
      flash[:notice] = 'Profile was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new' 
    end
  end

  # Update a profile
  # ====params
  # property:: Array of Property#id's to be associated with the Profile.
  # ====params[:profile]
  # title:: String for Profile#title
  # description:: String for Profile#description
  def update
    if @profile.update_attributes(params[:profile])
      @profile.add_properties(params[:property])
      current_user.ledgers.create(:source => 'You', :event => 'Profile Update',
                                  :target => '', :source_ip => request.remote_ip, 
                                  :login => current_user.login, :result => 'Success' )
      flash[:notice] = 'Profile was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  # Destroy a profile.
  # ====params
  # id:: Profile#id
  def destroy
    @profile.destroy
    respond_to do |type|
      type.html { redirect_to :action => 'list' }
      type.js   { render }
    end
  end

  protected
  # TODO Documentation: Comment these two methods?  Is it necessary.
    def find_profile # :nodoc:
      @profile = current_user.profiles.find(params[:id])
    end

    def find_global_or_owned_property_types # :nodoc:
      @global_or_owned_property_types ||= PropertyType.roots_global_or_owned_by(current_user)
    end

    def associate_properties_with_profile(properties)
      @profile.properties.clear
      @profile.add_properties(properties)
    end
end
