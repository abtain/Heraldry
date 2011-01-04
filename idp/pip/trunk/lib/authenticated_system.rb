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

  module AuthenticatedSystem
  protected
  def logged_in?
    current_user
  end

  # accesses the current user from the session.
  def current_user
    @current_user ||= session[:user] ? User.find_by_id(session[:user], :include => :avatar) : nil
  end

  # store the given user in the session. 
  def current_user=(new_user)
    session[:user] = new_user.nil? ? nil : new_user.id
    @current_user = new_user
  end

  def default_account_subdomain
    @current_user.login if logged_in?
  end

  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorized?(user)
     account_subdomain ? user.login.downcase == account_subdomain.downcase : true
  end

  def has_access?(user)
    logged_in? && current_user.login == user.login && authorized?(user)
  end

  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  # 
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end

  # To require logins, use:
  #
  #   before_filter :login_required                            # restrict all actions
  #   before_filter :login_required, :only => [:edit, :update] # only restrict these actions
  # 
  # To skip this in a subclassed controller:
  #
  #   skip_before_filter :login_required
  # 
  def login_required
    # skip login check if action is not protected
    return true unless protect?(action_name)

    # check if user is logged in and authorized
    return true if logged_in? and authorized?(current_user)
    
    # store current location so that we can 
    # come back after the user logged in
    store_location
    
    # call overwriteable reaction to unauthorized access
    access_denied and return false
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    flash[:notice] = "Your account, #{current_user.login}, does not have access to " +
                     "identity url: #{account_subdomain}.#{AppConfig.host(request.host)}.<br /> " +
                     "Please login with an account that can access this identity url." if logged_in? && !authorized?(current_user)
    redirect_to :controller=>"/account", :action =>"login"
  end  

  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session[:return_to] = request.request_uri
    session[:return_to_query] = request.env['QUERY_STRING']
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    session[:return_to] ? redirect_to_url(session[:return_to]) : redirect_to(default)
    session[:return_to] = nil
  end

  # adds ActionView helper methods
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?, :authorized?, :has_access?
  end
end
