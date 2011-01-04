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
# Table name: properties
#
#  id               :integer(11)   not null, primary key
#  user_id          :integer(11)   
#  property_type_id :integer(11)   
#  value            :text          
#  created_at       :datetime      
#  updated_at       :datetime      
#

# Used to store a value for a property.  It belongs to a User and to a PropertyType.
class Property < ActiveRecord::Base
  belongs_to :user
  belongs_to :property_type
  delegate :title, :title, :to => :property_type
  before_update :validate_format
  
  validates_presence_of :user_id, :property_type_id
  validates_uniqueness_of :property_type_id, :scope => :user_id

  # Returns the value of the property as a String. If the property is a date, then it returns a Date object.
  def value
    val = read_attribute(:value)
    return convert_select_date(val) if self.property_type.control_type == 'date_select' && val
    return val
  end

private
  def validate_format
    control_type = self.property_type.control_type
    format = self.property_type.format
    self.value = case
                 when control_type == 'date_select'
                   convert_select_date(self.value).to_s
                 when format && format =~ %r[^/.*/$]
                   (self.value =~ Regexp.new(format[2..-2]) ? self.value : '') 
                 else
                   self.value
                 end
  end
  
  # Convert a string or hash into a date object.
  def convert_select_date(date)
    return date if date.is_a?(Date)

    begin
      Date.strptime( date.is_a?(Hash) ? "#{date[:year]}-#{date[:month]}-#{date[:day]}" : date, '%Y-%m-%d' )
    rescue
      return nil
    end
  end

  def year_is_empty?(date)
    field_is_empty?(date, :year)
  end

  def month_is_empty?(date)
    field_is_empty?(date, :month)
  end

  def day_is_empty?(date)
    field_is_empty?(date, :day)
  end

  def field_is_empty?(hash, field)
    !hash[:field] || hash[field].empty?
  end
end
