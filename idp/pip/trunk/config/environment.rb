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

# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here

  # Skip frameworks you're not going to use
  config.frameworks -= [ :action_web_service ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options
  config.action_controller.allow_concurrency = false
end

APP_CONFIG = YAML::load(ERB.new(IO.read("#{RAILS_ROOT}/config/settings.yml")).result).symbolize_keys
APP_CONFIG[:app_host] = 'test.host' if ENV['RAILS_ENV'] == 'test'
APP_CONFIG[:restricted_names] = APP_CONFIG[:restricted_names] ? APP_CONFIG[:restricted_names].split(/\s*,\s*/) : []

api_keys_file = "#{RAILS_ROOT}/config/api_keys.yml"
if File.exists?(api_keys_file)
  api_keys = YAML::load(ERB.new(IO.read(api_keys_file)).result)

  if api_keys
    API_KEYS = api_keys.symbolize_keys
  else
    STDERR.puts "No keys in api_keys.yml."
  end
else
  STDERR.puts "No api_keys.yml file." # Don't want this to be an application killing error.
end

# The XMLSimple parser is breaking.  Turning off until it can be fixed.
# ActionController::Base.param_parsers[Mime::XML] = nil


# Set the domain for sessions to be the base domain.  Allows session sharing across subdomains.
# Does not work for 'localhost'
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update( :session_domain => '.'  + APP_CONFIG[:app_host]) unless APP_CONFIG[:app_host] == 'localhost'

ExceptionNotifier.exception_recipients = [APP_CONFIG[:admin_email]]
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update(:short_date => '%m/%d/%Y')

require 'core_ext'
require 'active_record_store'
require 'idp_captcha'
require 'tzinfo'

# Include your application configuration below
ActiveRecord::Base.class_eval do
  def to_dom_id
    [self.class.name.underscore, id] * '-'
  end
end

CGI::Session::ActiveRecordStore::Session.acts_as_raw :session_id, :data
Globalize::Language.acts_as_raw :pluralization

require 'lib/select_options'
require 'lib/app_config'
Engines.start


