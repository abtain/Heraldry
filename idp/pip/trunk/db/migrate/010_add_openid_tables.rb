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

class AddOpenidTables < ActiveRecord::Migration
  def self.up
    create_table :settings, :force => true do |t|
      t.column :setting, :string
      t.column :value, :binary
    end
    
    create_table :associations, :force => true do |t|
      t.column :server_url, :binary
      t.column :handle,     :string
      t.column :secret,     :binary
      t.column :issued,     :integer
      t.column :lifetime,   :integer
      t.column :assoc_type, :string
    end
    
    create_table :nonces, :force => true do |t|
      t.column :nonce,   :string
      t.column :created, :integer
    end
  end

  def self.down
    drop_table :nonces
    drop_table :settings
    drop_table :associations
  end
end
