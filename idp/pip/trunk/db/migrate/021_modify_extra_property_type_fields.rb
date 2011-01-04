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

class ModifyExtraPropertyTypeFields < ActiveRecord::Migration
  def self.up
    countries = PropertyType.find(:all, :conditions => "short_name like '%country%'")
    genders = PropertyType.find(:all, :conditions => "short_name like '%gender%'")
    time_zones = PropertyType.find(:all, :conditions => "short_name like '%timezone%'")
    languages = PropertyType.find(:all, :conditions => "short_name like '%language%'")

    countries.each {|c| c.control_type = 'select'; c.format = 'country'; c.properties.each{|p| p.update_attribute(:value, nil)}; c.save}
    genders.each {|g| g.control_type = 'select'; g.format = 'gender'; g.properties.each{|p| p.update_attribute(:value, nil)}; g.save}
    time_zones.each {|tz| tz.control_type = 'select'; tz.format = 'time_zone'; tz.properties.each{|p| p.update_attribute(:value, nil)}; tz.save}
    languages.each {|l| l.control_type = 'select'; l.format = 'language'; l.properties.each{|p| p.update_attribute(:value, nil)}; l.save}
  end

  def self.down
  end
end
