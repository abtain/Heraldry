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

class AddOpenidValues < ActiveRecord::Migration
  def self.up
    # run this if you have patched ActiveRecord::Base with the db/active_record_base_attributes.diff
    #PropertyType.load_from_file
    # otherwise, run this
    #if PropertyType.root && PropertyType.find_by_short_name('openid_sreg').nil?
    #  PropertyType.root.children.create :title => 'OpenID 1.2', :description => 'openid_sreg', :short_name => 'openid_sreg'
    #  openid = PropertyType.find_by_short_name('openid_sreg')
    #  openid.children.create :title => 'Email'          ,:short_name => 'email'       ,:description => 'Email'
    #  openid.children.create :title => 'Nickname'       ,:short_name => 'nickname'    ,:description => 'Nickname'
    #  openid.children.create :title => 'Full name'      ,:short_name => 'fullname'    ,:description => 'Full Name'
    #  openid.children.create :title => 'Gender'         ,:short_name => 'gender'      ,:description => 'Gender'
    #  openid.children.create :title => 'Date of Birth'  ,:short_name => 'dob'         ,:description => 'Date of Birth'
    #  openid.children.create :title => 'Postal Code'    ,:short_name => 'postcode'    ,:description => 'Postal Code'
    #  openid.children.create :title => 'Country'        ,:short_name => 'country'     ,:description => 'Country'
    #  openid.children.create :title => 'Language'       ,:short_name => 'language'    ,:description => 'Language'
    #  openid.children.create :title => 'Timezone'       ,:short_name => 'timezone'    ,:description => 'Time Zone'
    #end
  end

  def self.down
  end
end
