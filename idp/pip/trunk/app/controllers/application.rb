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

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ExceptionNotifiable
  include SslRequirement
  include ProprietaryCodeEngine

  before_filter :login_required
  # Require ssl for all requests except those excluded in individual controllers
  unless APP_CONFIG[:ssl_disabled]
    ssl_required
  end

  protected
  # Paginate a collection of objects according to the specified options
  #
  # ====Parameters
  # collection:: Array of objects
  # options:: per_page:: Number of objects to show per page.
  # page:: Page number of the current page.
  def paginate_collection(collection, options = {})
    default_options = {:per_page => 10, :page => 1}
    options = default_options.merge options

    pages = Paginator.new self, collection.size, options[:per_page], options[:page]
    first = pages.current.offset
    last = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end
  
  # Returns the account username from the url.
  # i.e. account_subdomain with http://user.idp.com/ => user
  # This method is also available as a helper method.
  def account_subdomain
    @account_subdomain ||= get_account_subdomain(request.host, AppConfig.host(request.host))
  end
  
  # Returns the account subdomain from the _request_host_.
  #
  # ====Paremeters
  # request_host:: The url being requested. (user.idp.com)
  # app_host:: The base url for the app. (idp.com)
  #
  # ====Example
  # get_account_subdomain('user.idp.com', 'idp.com') => 'user'
  def get_account_subdomain(request_host, app_host)
    if request_host =~ /(.*?)\.?#{app_host}$/ && !($1.empty? || $1 == 'www')
      $1
    elsif APP_CONFIG[:restricted_names].include?(request_host.split('.').last)
      request_host
    else
      nil
    end
  end
  
  # Creates a string representing a users identity url. This method is also
  # available as a helper method.
  #
  # ====Parameters
  # hsh is a hash of options described below.
  # username:: User#login.
  # app_host:: The base domain for the application.
  #
  # ====Example
  # identity_url(:username => 'user', :app_host => 'idp.com') => 'user.idp.com'
  def identity_url(hsh)
    if APP_CONFIG[:restricted_names].include?(hsh[:username].split('.').last)
      hsh[:username]
    else
      "#{hsh[:username]}.#{AppConfig.host(request.host)}"
    end
  end
  
  # Stores a secret code that must be passed when getting the avatar image.
  # This prevents image spoofing by other sites
  def create_secret_image_code
    session[:secret_code] ||= Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{current_user.login}--")
  end
  
  helper_method(:account_subdomain, :identity_url, :create_secret_image_code)
end
