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

begin
  require_gem "ruby-openid", ">= 1.0"
rescue LoadError
  require "openid"
end

# == About
# AccountController is responsible for user signup and account management.
#
# == Requirements
# SSL is used on all pages except #index, and #forgot_password.
# #index uses it on an account_subdomain in the index function.
#
# Login is required for #activate, #congratulations, #edit, #logout,
# #resend_confirmaton, #welcome.
#
# The two lists above may become out of date, be sure to check before_filter :login_required,
# ssl_required, and ssl_prohibited in the code for the most recent list.
class AccountController < ApplicationController
  unless APP_CONFIG[:ssl_disabled]
    ssl_required :except => [:index, :forgot_password]
    ssl_prohibited :only => [:forgot_password]
  end

  before_filter :login_required, :only =>
    [:activate, :congratulations, :edit, :logout, :resend_confirmaton, :welcome]
  observer :user_observer
  
  # Don't use the application layout when displaying certain actions
  layout "application", :except => [ :current_user, :login_required ]
  
  # Display the landing page for the app.
  # Also performs YADIS content-type negotiation when a subdomain is used.
  #
  # Redirect to AccountController#welcome if _current_user_ is logged in.
  def index
    redirect_to :action => 'welcome' if logged_in?
    if account_subdomain
      set_yadis_headers
      return(yadis_response) if yadis_request?(request)
    end
  end

  # Login the user and redirect to AccountController#Welcome.
  # If a _return_to_query_ and _return_to_ exist in the session, then
  # redirect the user to the _return_to_ url instead.
  #
  # Makes use of ActsAsAuthenticated methods in lib/authenticated_system.rb.
  # ====params
  # return_to_query:: The query for the _return_to_ url. Primarily used with OpenID.
  # return_to:: A url to redirect the user to after login.
  # previous_protocol:: The protocol to be used on redirection
  #
  # login:: User#login
  # password:: User#password
  def login
    get_session_variables_from_authenticated_system

    return unless request.post?
    attempt_to_login_user

    if logged_in? && authorized?(current_user)
      create_secret_image_code
      set_session_variables_for_authenticated_system
      log_the_login
      redirect_with_proper_protocol_and_query_string
    elsif account_subdomain
      flash.now[:notice] = "Bad username or password for identity url: #{account_subdomain}.#{AppConfig.host}"
    else
      flash.now[:notice] = "Bad username or password."
    end
  end

  # Return the signup form.
  def signup
    @user = User.new
  end
  
  # Creates a new User in the database and redirects the user to 
  # AccountController#congratulations.
  # ====params
  # captcha:: The captcha code entered by the user.
  # ====params[:user]
  # login:: User#login.
  # password:: User#password.
  # password_confirmation:: User#password_confirmation.
  # email:: User#email.
  def complete_signup
    @user = User.new(params[:user])
    
    params[:captcha].upcase! if params[:captcha]
    check_for_signup_errors

    if @user.errors.empty? && @user.save
      @session['captcha_code'] = nil
      self.current_user = User.authenticate(@user.login,params[:user][:password])
      create_secret_image_code
      log_the_login
      redirect_back_or_default(:controller => '/account', :action => 'congratulations')
    else
      render :action => 'signup'
    end
  end
 
  # Activate the User with activation_code == _id_ and redirect to 
  # AccountController#welcome. If no User is found, redirect to 
  # AccountController#welcome.  There is always a logged-in user due
  # to the filter chain.
  # ====params
  # id:: User#activation_code
  def activate
    @user = User.find_by_activation_code(params[:id]) if params[:id]
    
    #Did we find a user?
    if @user
      # Is the logged-in user the one found by the activation code?
      if (self.current_user == @user)
        if @user.activate
          redirect_back_or_default(:controller => '/account', :action => 'welcome')
          flash[:notice] = "Your e-mail address has been verified."
        else
          redirect_to :controller => '/account', :action => 'index'
        end
      else
        # Another user tried to log in on someone's verification code
        flash[:notice] = "You are not the account holder to whom the verification email was sent.  You cannot login at this time."
        logout #Since we are assuming something malicious
      end
    else
      # No user found for that activation code, show an error
      flash[:error] = "The activation code submitted was invalid; please try again."
      redirect_to :controller => '/account', :action => 'welcome'
    end
  end

  # Logout the _current_user_ and redirect to AccountController#index.
  def logout
    self.current_user = nil
    
    #flash[:notice] = "You have been logged out."
    session[:return_to] = '/' if session[:return_to] && session[:return_to] =~ /server/
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end

  # Edit account settings for the _current_user_.
  # ====params
  # No params other than params[:user]
  # ====params[:user]
  # login:: User#login
  # password:: User#password
  # password_confirmation:: User#password_confirmation
  # email:: User#email
  # avatar_data:: An uploaded picture
  def edit
    return unless request.post?
    if current_user.update_attributes(params[:user])
      flash.now[:notice] = 'Your Account Settings were updated successfully.'
    else
      flash.now[:error] = 'Your Account Settings could not be updated.'
    end
  end
  
  # Render and process a form for forgotten passwords.
  # This page allows the user to enter his email address
  # and receive an email which will allow him to reset his password.
  # ====params
  # email:: User#email
  def forgot_password
    return unless request.post?
    @user = User.find_by_email(params[:email])
    if @user.nil?
      flash.now[:error] = "We couldn't find your account. Please check to make sure that the information you entered below is correct."
    else
      @user.make_activation_code
      @user.save
      UserNotifier.deliver_password_reset(@user)
      flash.now[:notice] = "We have found your account and emailed you a link you can use to reset your password. " +
                       "If you have any questions or need assistance, please contact us."
      render :action => 'index'
    end
  end

  # Form for resetting a User's password. Logs in the User after password reset
  # and redirects to AccountController#welcome.
  # ====params
  # id:: User#activation_code
  # ====params[:user]
  # password:: User#password
  # password_confirmation:: User#password_confirmation
  def reset_password
    return unless request.post?
    @user = User.find_by_activation_code(params[:id]) if params[:id]
    if @user && @user.update_attributes(params[:user]) && @user.activate
      self.current_user = @user
      flash[:notice]    = "Your password has been reset."
      redirect_to :action => 'welcome'
    else
      flash.now[:error]     = "Your password was not reset."
    end
  end

  # Resend the confirmation email for _current_user_. This allows a user
  # to receive a new activation link with which to activate his account.
  # ====params
  # email:: User#email
  #--
  def resend_confirmation
    return unless request.post?
    if current_user.activated_at
      flash.now[:error] = "Your account has already been activated."
    else
      UserNotifier.deliver_signup_notification(current_user)
      flash.now[:notice] = "Your confirmation email has been re-sent"
      render :action => 'index'
    end
  end
  
  protected
  # Returns the host name with the port being used (unless the port is 443 or 80).
  def host_with_port
    AppConfig.host(request.host) + (port_needed? ? ':' + request.port.to_s : '')
  end
  
  def port_needed?
    request.port && ![443, 80].include?(request.port)
  end

  # Returns true if the current request is a Yadis request.
  # ====params
  # request:: A rails request object.
  def yadis_request?(request)
    (request.env['HTTP_ACCEPT'] && request.env['HTTP_ACCEPT'].include?('application/xrds+xml'))
  end
  
  def set_yadis_headers
    @host = host_with_port
    # Corresponds to uri in config/mongrel.conf
    @uri = 'user'
    login = account_subdomain.gsub(/\./, '_')

    response.headers['X-XRDS-Location'] = 
        "http://#{@host}/#{@uri}/#{login}/yadis"
        response.headers['X-YADIS-Location'] = 
        "http://#{@host}/#{@uri}/#{login}/yadis"
  end

  def yadis_response
    response.headers['Content-Type'] = 'application/xrds+xml'
    render( :text => Mongrel::Yadis::YadisHandler.
                       yadis_document_for(account_subdomain.gsub(/\./, '_'),
                                          @host,
                                          @uri)) 
  end

  # This method removes authenticated_system variables from the session
  # to prevent improper session redirects.
  def get_session_variables_from_authenticated_system
    @return_to_query = session[:return_to_query] || params[:return_to_query]
    @return_to = session[:return_to] || params[:return_to]
    @previous_protocol = session[:previous_protocol] || params[:previous_protocol]
    session[:return_to_query] = session[:return_to] = session[:previous_protocol] = nil
  end

  def attempt_to_login_user
    self.current_user = User.authenticate(params[:login], params[:password])
  end 


  def set_session_variables_for_authenticated_system
    session[:return_to] = (@return_to == "" ? nil : @return_to)
    session[:return_to_query] = (@return_to_query == "" ? nil : @return_to_query)
  end
 
  def log_the_login
    current_user.ledgers.create(:source => 'You', :event => 'Login',
                                :target => '', :source_ip => request.remote_ip, 
                                :login => current_user.login, :result => 'Success')
  end

  def redirect_with_proper_protocol_and_query_string
    logger.info "return_to_query: #{@return_to_query.inspect}"
    parsed_query = CGI.parse(@return_to_query || '')
    logger.info "parsed_query: #{parsed_query.inspect}"
    unless parsed_query['openid.mode'].empty?
      url = ("#{server_url}?#{@return_to_query}")
      if @previous_protocol == 'http://'
        url.gsub!('https://', 'http://')
      else
        url.gsub!('http://', 'https://')
      end

      redirect_to(url)
    else
      redirect_back_or_default(:controller => '/account', :action => 'welcome')
    end
  end

  def check_for_signup_errors
    @user.valid?
    unless params[:captcha] == @session['captcha_code']
      @captcha_error = 'Incorrect entry for image letters. Please try again.'
      @user.errors.add_to_base(@captcha_error)
    end
    if @user.login && APP_CONFIG[:restricted_names].include?(restricted = @user.login.split('.').last)
      @user.errors.add(:login, " cannot end with #{restricted}.")
    end
  end

  helper_method(:host_with_port) 
end
