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

#--
# TODO DOCUMENTATION: Document this controller.
class AvatarController < ApplicationController
  # Return the _current_user_'s Avatar.
  #
  # Should be called via a view using <img src="avatar/show" />.
  def show
    return(render :text => 'No access') unless session[:secret_code] && params[:secret_code] == session[:secret_code]

    @user = User.find(:first, :select => "users.id, avatars.content_type, db_files.data",
      :conditions => ['users.login = ?', current_user.login],
      :joins => 'inner join avatars on users.id = avatars.user_id inner join db_files on avatars.db_file_id = db_files.id')
    if (@user.respond_to?(:data) && @user.data)
      send_data(@user.data, :type => @user.content_type, :disposition => 'inline')
    else
      send_file('public/images/id_image.gif', :type => 'image/gif', :disposition => 'inline')
    end
  end

  # Allow the user to upload an avatar image. Redirects to 
  # AccountController#congratulations.
  # ====params
  # avatar_data:: An uploaded picture.
  def create
    if params[:user] && params[:user][:avatar_data]
      if params[:user][:avatar_data].size <= 0
        flash[:error] = "Please choose an image to upload."
      elsif !Technoweenie::ActsAsAttachment.content_types.include?(file_type = params[:user][:avatar_data].content_type.strip)
        flash[:error] = "Sorry, we only support jpg, png, and gif files for ID Images."
      elsif current_user.update_attributes(params[:user])
        flash[:notice] = "Your ID Image was uploaded successfully"
      else
        flash[:error] = "Your ID Image was not uploaded."
      end
    end
    redirect_to :controller => 'account', :action => 'congratulations'
  end

end
