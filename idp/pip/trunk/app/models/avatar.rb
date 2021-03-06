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
# Table name: avatars
#
#  id           :integer(11)   not null, primary key
#  user_id      :integer(11)   
#  filename     :string(255)   
#  content_type :string(255)   
#  size         :integer(11)   
#  width        :integer(11)   
#  height       :integer(11)   
#  db_file_id   :integer(11)   
#  parent_id    :integer(11)   
#

# This class is used to store user images.
class Avatar < ActiveRecord::Base
  acts_as_attachment :content_type => :image, :resize_to => "70x70"
  belongs_to :user

end
