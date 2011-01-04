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

ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'server' do |m|
 #   m.identity 'user/:username'
    m.server   'server'
    m.server   'server/:action', :action => 'index'
  end
  
  map.connect '', :controller => "account"

  map.profiles  '/profiles', :controller => 'profiles', :action => 'index'
  map.profile 'profile/:action', :controller => 'profiles', :action => 'index'

  map.with_options :controller => 'account' do |m|
    m.account 'account/:action',  :action => 'index'
    m.logout  'account/logout',   :action => 'logout'
    m.login   'account/login',    :action => 'login'
    m.signup  'account/signup',   :action => 'signup'
    m.account 'account',          :action => 'index'
  end

  map.trusts    'trusts', :controller => 'trusts', :action => 'list'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
