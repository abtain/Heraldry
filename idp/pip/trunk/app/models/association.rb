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

# == Schema Information
# Schema version: 27
#
# Table name: associations
#
#  id         :integer(11)   not null, primary key
#  server_url :binary        
#  handle     :string(255)   
#  secret     :binary        
#  issued     :integer(11)   
#  lifetime   :integer(11)   
#  assoc_type :string(255)   
#

begin
  require_gem "ruby-openid", ">= 1.0"
rescue LoadError
  require "openid"
end

# Stores OpenID Associations. Used in conjunction with the JanRain OpenID libraries.
class Association < ActiveRecord::Base
  # Return an OpenID::Association given an Association.
  def from_record
    OpenID::Association.new(handle, secret, issued, lifetime, assoc_type)
  end
end
