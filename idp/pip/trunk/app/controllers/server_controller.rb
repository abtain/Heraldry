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

require 'rexml/document'

# == About
# ServerController handles all OpenID interchange between consumer sites and the app. 
# It also manages the xml api for OpenID. See www.openiedenabled.com for more information.
#
# == Requirements
# Login is required on all actions if the request is made from a browser.
# Requests from consumer sites do not require a login.
#
# SSL is only required if the initial request is made via SSL.
class ServerController < ApplicationController
  before_filter :validate_post_is_secure, :except => [:index]
  layout nil
  skip_before_filter :ssl_required
  before_filter :check_for_xml, :only => :index
  before_filter :login_required,  :only => [:trust_request, :decision]
  before_filter :verify_current_user_owns_identity_url, :only => :index
  before_filter :check_for_human, :only => :index

  # The primary point of entry for all outside contact with server controller.
  # Handles three types of requests: one from consumer sites, one from users at a browser,
  # and a third from the xml api.
  #
  # ====Consumer sites
  # Consumer sites make requests to initiate associations and verify association data.
  # These requests do not require a login or ssl.
  #
  # ====User requests
  # These requests are redirects from a consumer site that determine if the consumer
  # site is allowed access to the user's information.
  #
  # ====XML requests
  # These are similar to user requests except make use of the XML api. In addition, there
  # is additional functionality for creating trusts.
  def index
    return render(:text => "This is an OpenID server endpoint.") unless openid_request

    if checkid_request?
      if consumer_site_is_authorized?
        log_the_action
        inform_the_consumer_site :it_is_authorized
      elsif is_xml_request?
        inform_the_xml_agent :it_is_not_authorized
      elsif request_is_checkid_immediate?
        inform_the_consumer_site :it_is_not_authorized
      elsif request_is_checkid_setup?
        redirect_user_to_create_new_authorization
      else
        raise 'The chain should not have gotten this far in Server#index'
      end
    else # Must be an association request
      inform_the_consumer_site :it_has_an_association
    end
  end

  # Process the User's decision on an openid.checkid_setup request.
  # ====params
  # query:: Original openid query string.
  # trust_profile:: Trust#id of the trust profile being used. Use -1 if a new 
  #                 trust_profile is being created.
  # profile_name:: Name of the new Profile (if one is being created).
  # property:: Array of property ids to use with the Profile (if one is 
  #            being created).
  # keep_until:: The length of time to for the Trust to be active. 
  #              Accepted values: 'forever', 'exact', 'once'.
  # date:: The exact date at which the Trust expires. A hash of three self 
  #        explanatory keys: :year => yyyy, :month => mm, & :day => dd.
  # yes.y:: If this contains a value, then the user approved the trust_request.
  def decision 
    return unless trust_request_param_exists? && trust_profile_chosen?

    params.merge! CGIMethods.parse_query_parameters(params[:query])
    authorize_the_consumer_site unless consumer_site_is_authorized?
    inform_the_consumer_site(:it_is_authorized) unless performed?
  end

protected
  def trust_request_param_exists?
    unless params[:query]
      flash[:error] = 'Sorry, this trust request has already expired.'
      redirect_to(:controller => 'account', :action => 'welcome')
      return false
    end
    true
  end

  def trust_profile_chosen?
    unless params[:trust_profile]
      flash[:error] = 'Please create a trust profile.'
      redirect_to(:controller => 'profiles', :action => 'new') 
      return false
    end
    true
  end

  def checkid_request?
    openid_request.is_a? OpenID::Server::CheckIDRequest
  end

  def required_fields
    @required_fields ||= params['openid.sreg.required'] ? params['openid.sreg.required'].split(',') : []
  end 

  def optional_fields
    @optional_fields ||= params['openid.sreg.optional'] ? params['openid.sreg.optional'].split(',') : []
  end
  
  # Returns true if the user is logged in and owns the trust_root.
  # ====Parameters
  # url:: The User's identity url.
  # trust_root:: The consumer site's trust root.
  # required_properties:: An array of properties the Profile must have.
  #                       ! NOT CURRENTLY USED !
  #--
  # TODO: Make consumer_site_is_authorized? return false if the Profile does not have
  #       the required properties.
  def consumer_site_is_authorized?
    return false unless current_user
    if user_owns_identity_url?
      return true if (trust = current_user.trusts.find_by_trust_root(openid_request.trust_root)) && trust.active?
    end
    return false
  end
 
  def request_is_checkid_immediate?
    openid_request.immediate
  end

  def request_is_checkid_setup?
    !openid_request.immediate
  end

  # Returns true if the current user owns openid_request.identity_url
  def user_owns_identity_url?
    current_user && current_user.login.downcase == extract_identity(openid_request.identity_url)
  end

  def log_the_action
    Ledger.create(:source => openid_request.trust_root, :event => 'Trust Request', :target => openid_request.identity_url,
                  :source_ip => request.remote_ip, :login => current_user.login, :result => 'Authorized')
  end

  def inform_the_consumer_site(action)
    case action
    when :it_is_authorized
      @trust ||= current_user.trusts.find_by_trust_root(openid_request.trust_root)
      @resp = openid_request.answer(true)
      add_sreg
    when :it_is_not_authorized
      retry_query = params.delete_if {|key, val| val.nil?}
      retry_query['openid.mode'] = 'checkid_setup'
      setup_url = OpenID::Util.append_args(server_url(:action => 'index'), retry_query)
	    @resp = openid_request.answer(false, setup_url)
      # Hackery to circumvent JanRain library bug in req.answer.
      @resp.fields['user_setup_url'] = setup_url 
    when :it_has_an_association
      @resp = server.handle_request(openid_request)
    else
      raise "Bad action: #{action}"
    end
    render_response
  end

  def redirect_user_to_create_new_authorization
    return render_trust_request(request.env['QUERY_STRING'])
  end

  def a_profile_was_chosen?
    !(params[:trust_profile] == '-1')
  end

  def find_the_profile
    @profile = current_user.profiles.find_by_id(params[:trust_profile])
  end

  def create_a_new_profile
    @profile = current_user.profiles.build(:title => params[:profile_name])
    @profile.add_properties(params[:property])
    unless @profile.save || ((!params[:profile_name] || params[:profile_name].empty?) &&
                              params[:keep_until] == 'once')
      current_user.profiles.reload
      set_flash_error_message
      @profile = nil
    end
  end

  def set_flash_error_message
    if @profile.errors.full_messages.include?('Title can\'t be blank')
      flash.now[:error] = @profile.errors.full_messages.delete_if{|m| m == 'Title can\'t be blank'} <<
                          'Please choose or create a trust profile.'
    else
      flash.now[:error] = @profile.errors.full_messages
    end
  end

  def authorize_the_consumer_site
    if a_profile_was_chosen?
      find_the_profile
    else
      create_a_new_profile
    end
    unless @profile
      flash.now[:error] == 'Invalid Profile' unless flash[:error]
      return render_trust_request(params[:query])
    end

    create_trust
    log_the_action
  end

  def create_trust
    case params[:keep_until]
    when 'forever'  
      expires_at = nil
    when 'exact'
      expires_at = Time.gm(params[:date][:year], params[:date][:month], params[:date][:day]).utc
    end
    if @trust = @profile.trusts.find_by_trust_root(openid_request.trust_root)
      @trust.update_attributes(:profile => @profile, :expires_at => expires_at)
    else
      @trust = Trust.create :profile => @profile, :expires_at => expires_at, :trust_root => openid_request.trust_root
    end
    @trust.update_attributes(:expires_at => Time.now.utc) if params[:keep_until] == 'once'
  end

  def openid_request
    unless @openid_request
       params.each {|key, val| params[key] = '' if val.nil?}
       @openid_request = server.decode_request(params.delete_if{|key, val| key == 'openid.session_type' && val == ''})
    end
    @openid_request
  end

  # Returns true if the _current_user_ owns the identity url.  If there is a
  # logged in user, then also sets up an error message if they do not own the
  # identity url.
  # Identity urls follow the format of http://idp.com/user/[_user_login_] and
  # http://[_user_login_].idp.com/
  def verify_current_user_owns_identity_url
    if !openid_request.is_a?(OpenID::Server::CheckIDRequest) || openid_request.mode == 'checkid_immediate' ||
       user_owns_identity_url?
      return true
    elsif current_user
      # Use sessions here since they may not immediatly goto the login page, so it needs
      # to persist.
      flash[:notice] = "You do not own #{CGI.escapeHTML(params['openid.identity'])}." +
                        " Please login with an account that owns this url."
      flash.keep :notice

      # Don't need to "store_location" since this will happen later when calling
      # "openid_login_required" from "check_for_human"

      # Tell the view that the user is logged in, though as someone else
      flash[:not_owner] = true

      # At this point redirect to the appropriate login page
      openid_login_needed
    end
  end
  
  # If the request is coming from a user at a browser, require the user to login.
  def check_for_human
    session[:previous_protocol] = request.protocol
    
    # If this is a "checkid_setup" request, make sure we have a logged in user
    if openid_request.is_a?(OpenID::Server::CheckIDRequest) && openid_request.mode == 'checkid_setup'
      return true if current_user
      
      openid_login_needed
    else
      return true
    end
  end
  
  def openid_login_needed
    store_location

    if APP_CONFIG[:safe_signin]
      redirect_to :controller=>"/account", :action =>"login_required" and return false
    else
      redirect_to :controller=>"/account", :action =>"login" and return false
    end
  end

  def server # :nodoc:
    @server ||= OpenID::Server::Server.new(ActiveRecordOpenIDStore.new)
  end
  
  # Gets the username from an identity string
  # extract_identity('http://user.idp.com') => 'user'
  # extract_identity('http://idp.com/user/user_login') => 'user_login'
  #--
  # TODO: Verify that this isn't the same as a method in ApplicationController
  def extract_identity(uri)
    return $1.downcase if uri =~ %r[/user/([a-zA-Z_1-9-]*)] || uri =~ %r[://([a-zA-Z_1-9-]*)?\.#{AppConfig.host(request.host)}] || uri =~ %r[://(.*?)/?$]
    return nil
  end
  
  # this method needs to check three things:
  # 1. Is the user logged in
  # 2. Is the given URL the identity_url for the logged in user?
  # 3. Is the trust root approved?
  # 
  
  # Adds the requested profile data to the openid query string.
  #
  # ====Parameters
  # required:: An array of required fields.
  # optional:: An array of optional fields.
  # response:: The openid response the fields are being added to.
  # profile:: The profile data is retrieved from.
  #--
  # TODO: Merge required and optional so that only one argument is passed.
  def add_sreg
    sreg = {}
    fields = (required_fields || []) + (optional_fields || [])
    openid = current_user.properties.openid
    profile = @trust ? @trust.profile : nil
    unless profile.nil?
      fields.each do |field|
        if property = profile.properties.send("value_for_#{openid[field]}")
          sreg[field] = format_sreg(property, field)
        end
      end
    end
    
    @resp.add_fields('sreg', sreg)  
  end

  # The conversion parameters for OpenID gender.
  #--
  # TODO: Is there a better place to put this.
  OPENID_SREG_GENDER = {'male' => 'm', 'female' => 'f'}

  # Format a property value to match the format required by OpenID.
  # ====Parameters
  # property:: Property#value
  # sreg:: The lowercase sreg parameter. i.e. - 'dob' or 'gender'
  def format_sreg(property, sreg)
    return '' unless property
    
    case sreg.downcase
    when 'dob'
      return property.to_s
    when 'gender'
      return OPENID_SREG_GENDER[property.downcase] || ''
    # Hacky way to handle american timezones
    #--
    # TODO: Make this not so hacky. Maybe use a model to convey idea of timezone.
    #++
    # This really isn't something that should exist within ServerController.
    when 'timezone'
      case property
      when 'us_eastern'
        return 'America/New_York'
      when 'us_central'
        return 'America/Chicago'
      when 'us_mountain'
        return 'America/Denver'
      when 'us_pacific'
        return 'America/Los_Angeles'
      else
        return property
      end
    else
      return property
    end
  end

  # Renders the trust request page.
  # ====Parameters
  # req:: The OpenID::Server::CheckIDRequest object.
  # required_fields:: An array of required fields.
  # optional_fields:: An array of optional fields.
  # query_string:: The original openid query_string.
  def render_trust_request(query_string)
    required_fields.map!{ |f| current_user.properties.openid[f] }
    optional_fields.map!{ |f| current_user.properties.openid[f] }
    @openid_map = current_user.properties.openid
    @properties = current_user.properties.delete_if{ |p| !(required_fields + optional_fields).include?(p.property_type.short_name)}
    @trust_root      = openid_request.trust_root
    @identity_url    = openid_request.identity_url
    @query_string    = query_string
    return render(:action => 'trust_request', :layout => 'application')
  end

  # Renders the redirect response for an OpenID request.
  # ====Parameters
  # response:: An OpenID::Server::OpenIDResponse object.
  def render_response
    response.headers['Content-Type'] = 'charset=utf-8'
    @resp = server.encode_response(@resp)
    return render_xml_response if is_xml_request?
    case @resp.code
    when OpenID::Server::HTTP_OK
      render :text => @resp.body, :status => 200
    when OpenID::Server::HTTP_REDIRECT
      redirect_to @resp.redirect_url
    else
      render :text => @resp.body, :status => 400
    end   
  end

	 	   
  # Stops the filter chain if the request is meant for the XML api. 
  #-- 
  # TODO: Document xml api. 
  def check_for_xml 
    return true unless is_xml_request? 
    return(render(:text => '<Response>Error: bad xml</Response>')) unless @request.env['RAW_POST_DATA'] && !@request.env['RAW_POST_DATA'].strip.empty? 

    # headers['Content-Type'], NOT headers['CONTENT_TYPE'] 
    @response.headers['CONTENT_TYPE'] = 'text/xml; charset=utf-8' 
    @response.headers['Content-Type'] = 'text/xml; charset=utf-8' 

    xml = REXML::Document.new(request.env['RAW_POST_DATA']) 
    login_user(xml) 
    return(render(:text => '<Response>bad username or password</Response>') and false) unless current_user 

    begin 
      (delete_trust(xml) and return false) if is_delete_trust? 
      (create_trust_xml(xml) and return false) if is_create_trust? 
      (xml_profile_list(xml) and return false) if is_profile_list? 
      (xml_query_profile(xml) and return false) if is_query_profile? 

      params.merge!(get_params_from_xml(xml)) 

	 	  create_trust_if_necessary(xml) 
	 	rescue 
 	    return(render(:text => '<Response>Error: bad xml format.</Response>')) 
    end
  end

  ########## For handling xml requests ############# 
	 	   
  # Returns true if this is an xml request. 
  def is_xml_request? 
    request.env['CONTENT_TYPE'] =~ %r[(application|text)/xml] 
  end 
	 	   
  # Returns true if this is an xml request to delete a trust. 
  def is_delete_trust? 
    request.env['RAW_POST_DATA'] =~ %r[<DeleteTrust>] 
  end 
	 	   
  # Parses and executes a delete trust command. 
  # 
  # ====Parameters 
  # xml:: The raw xml post data. 
  #-- 
  # TODO DOCUMENTATION: Explain the format. 
  def delete_trust(xml) 
    if current_user 
      trust_root = xml.root.get_elements('TrustRoot').first.text 
      unless trust_root.empty? 
        @trust = current_user.trusts.find(:first, :conditions => ['trust_root = ?', trust_root]) 
        if @trust 
          @trust.destroy 
          return render(:text => "<Response>success</Response>") 
        end 
      end 
    end 
    render :text => '<Response>trust root does not exist</Response>' 
  end 
   
  # Returns true if this is an xml request to delete a trust. 
  def is_create_trust? 
    request.env['RAW_POST_DATA'] =~ %r[<CreateTrust>] 
  end 
   
  # Parses and executes a create trust command. 
  # 
  # ====Parameters 
  # xml:: The raw xml post data. 
  #-- 
  # TODO DOCUMENTATION: Explain the format. 
  def create_trust_xml(xml) 
    if current_user 
      empty = REXML::Element.new('empty') 
      trust = xml.root.get_elements('Trust').first 
     
      return render(:text => "<Response>bad xml</Response>") unless trust 
      trust_root = (trust.get_elements('TrustRoot').first || empty).text 
      expires = (trust.get_elements('Expires').first || empty).text 
      profile_name = (trust.get_elements('AccessProfile').first || empty).text 
      profile_name = 'public' unless profile_name 
      @profile = current_user.profiles.find_by_title(profile_name) 
       
      return render(:text => "<Response>bad profile</Response>") unless @profile 
       
      if ['-1', '0'].include? expires 
        expires_at = nil 
      else 
        expires =~ %r[(\d+)/(\d+)/(\d+)] 
        expires_at = Time.utc($3.to_i, $2.to_i, $1.to_i) 
      end 
       
      if @trust = Trust.find_by_trust_root(trust_root) 
        @trust.update_attributes(:profile => @profile, :expires_at => expires_at) 
      else 
        @trust = Trust.create(:profile => @profile, :expires_at => expires_at, :trust_root => trust_root) 
      end 
      @trust.update_attributes(:expires_at => Time.now.utc) if expires == '0' 
      return render(:text => '<Response>success</Response>') 
    end 
    render :text => '<Response>could not create trust</Response>' 
  end 
   
  # Returns true if this is an xml request to show a list of available profiles. 
  def is_profile_list? 
    request.env['RAW_POST_DATA'] =~ %r[<QueryProfileList>] 
  end 
   
  # Parses and executes an xml list profile command. 
  # ====Parameters 
  # xml:: The raw xml post data. 
  #-- 
  # TODO DOCUMENTATION: Explain the format. 
  def xml_profile_list(xml) 
    if current_user 
      profiles = current_user.profiles.map{|p| p.title}.join(',') 
      return render(:text => "<Response>#{profiles}</Response>") 
    end 
    render :text => '<Response>Internal Error</Response>' 
  end 
	 	   
  # Returns true if this is an xml request to query a profile. 
  def is_query_profile? 
    request.env['RAW_POST_DATA'] =~ %r[<QueryProfile>] 
  end 
	 	   
  # Parses and executes an xml query profile command. 
  # ====Parameters 
  # xml:: The raw xml post data. 
  #-- 
  # TODO DOCUMENTATION: Explain the format. 
  def xml_query_profile(xml) 
    if current_user 
      profile_name = (xml.root.get_elements('AccessProfile').first || empty).text 
      profile_name = 'public' unless profile_name 
      @profile = current_user.profiles.find_by_title(profile_name) 
      return render(:text => "<Response>bad profile</Response>") unless @profile 
       
      properties = @profile.properties.map{|p| p.property_type.title }.join(',') 
      return render(:text => "<Response>#{properties}</Response>") 
    end 
    render(:text => "<Response>Internal Error</Response>") 
  end 
   
  # Login the user via an xml request 
  # ====Parameters 
  # xml:: The raw xml post data 
  def login_user(xml) 
    login = xml.root.get_elements('User').first.text 
    password = xml.root.get_elements('Password').first.text 
    self.current_user = User.authenticate(login, password) 
  end 
   
  # Creates a one use trust if necessary for the given trust_root. 
  #  
  # ===Parameters 
  # xml:: The raw xml post data 
  def create_trust_if_necessary(xml) 
    profile_name = xml.root.get_elements('Request').first.get_elements('AccessProfile').first.text 
    profile_name = 'public' unless profile_name 
    profile = current_user.profiles.find_by_title(profile_name) 
    return unless profile 
    hsh = {:profile => profile} 
    params.merge!(get_params_from_xml(xml)) unless params['openid.mode'] 
    if @trust = Trust.find_by_trust_root(params['openid.trust_root']) 
      unless @trust.active? 
        hsh.merge!(:expires_at => nil)  
        just_once = true 
      end 
      @trust.update_attributes(hsh) 
    else 
      @trust = Trust.create :profile => profile, :expires_at => nil, :trust_root => params['openid.trust_root'] 
      just_once = true 
    end 
    @trust.instance_eval "def xml_expire?; #{just_once}; end" 
  end 
   
  # Extracts OpenID params from an xml request and returns them as a hash. 
  # ====Parameters 
  # xml:: Raw xml post data. 
  def get_params_from_xml(xml) 
    empty = REXML::Element.new('empty') 
    empty_attr = REXML::Attribute.new('empty') 
    ret = {} 
    root = xml.root 
 
    ret.merge!('openid.mode' => "checkid_#{$1.downcase}") if root.xpath =~ /OpenIDCheckID(.*)/ 
    if req = root.get_elements('Request').first 
      ret.merge!('openid.identity' => ((req.get_elements('Identity').first || empty).text || '').strip, 
                 'openid.assoc_handle' => ((req.get_elements('AssocHandle').first || empty).text || '').strip, 
                 'openid.return_to' => ((req.get_elements('ReturnTo').first || empty).text  || '').strip, 
                 'openid.trust_root' => ((req.get_elements('TrustRoot').first || empty).text || '').strip) 
      if sreg = req.get_elements('Sreg').first 
        ret.merge!('openid.sreg.required' => ((sreg.attribute('required') || empty_attr).value || '').strip, 
                   'openid.sreg.optional' => ((sreg.attribute('optional') || empty_attr).value || '').strip, 
                   'openid.sreg.policy_url' => ((sreg.attribute('policy_url') || empty_attr).value || '').strip) 
      end 
    end 
    return ret 
  end 
   
  # Render a response to an xml request. 
  # Response is rendered in xml. 
  # ====Parameters 
  # resp:: An OpenID::Response object. 
  def render_xml_response 
    @trust.update_attributes(:expires_at => Time.now.utc) if @trust && @trust.xml_expire? 
    response.headers['CONTENT_TYPE'] = 'text/xml; charset=utf-8' 
    response.headers['Content-Type'] = 'text/xml; charset=utf-8' 
    render :text => "<Response>#{@resp.headers['location'].gsub(/&/,'&#38;')}</Response>" 
  end

  def inform_the_xml_agent(action)
    case action
    when :it_is_not_authorized
      if request_is_checkid_immediate?
        setup_url = server_url(:action => 'index')
        @resp = openid_request.answer(false, setup_url)
      else
        @resp = openid_request.answer(false)
      end
    else
      raise "Bad action: #{action}"
    end
    render_response
  end

  helper_method(:openid_request, :required_fields, :optional_fields)
end
