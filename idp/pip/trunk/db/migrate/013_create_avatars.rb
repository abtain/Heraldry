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

class CreateAvatars < ActiveRecord::Migration
  def self.up
    remove_column "users", "filename"
    remove_column "users", "content_type"
    remove_column "users", "size"
    remove_column "users", "width"
    remove_column "users", "height"
    create_table :avatars do |t|
      t.column :user_id, :integer
      t.column :filename, :string
      t.column :content_type, :string
      t.column :size, :integer
      t.column :width, :integer
      t.column :height, :integer
    end
  end

  def self.down
    add_column "users", "filename", :string
    add_column "users", "content_type", :string
    add_column "users", "size", :integer
    add_column "users", "width", :integer
    add_column "users", "height", :integer
    drop_table :avatars
  end
end
