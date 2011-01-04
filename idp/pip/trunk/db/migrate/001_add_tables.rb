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

class AddTables < ActiveRecord::Migration
  def self.up
    create_table "ledgers", :force => true do |t|
      t.column "user_id", :integer
      t.column "transaction", :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "trust_id", :integer
    end

    create_table "personas", :force => true do |t|
      t.column "user_id", :integer
      t.column "name", :string
      t.column "description", :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "properties", :force => true do |t|
      t.column "user_id", :integer
      t.column "property_type_id", :integer
      t.column "name", :string
      t.column "value", :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "property_types", :force => true do |t|
      t.column "parent_id", :integer
      t.column "title", :string
      t.column "short_name", :string
      t.column "mime_type", :string
      t.column "description", :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "trusts", :force => true do |t|
      t.column "user_id", :integer
      t.column "persona_id", :integer
      t.column "title", :string
      t.column "url", :string
      t.column "is_active", :boolean, :default => true
      t.column "expires_at", :datetime
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "users", :force => true do |t|
      t.column "login", :string, :limit => 40
      t.column "email", :string, :limit => 100
      t.column "crypted_password", :string, :limit => 40
      t.column "salt", :string, :limit => 40
      t.column "activation_code", :string, :limit => 40
      t.column "activated_at", :datetime
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "identity_url", :string
    end
  end

  def self.down
    drop_table :ledgers
    drop_table :personas
    drop_table :properties
    drop_table :users
    drop_table :trusts
    drop_table :property_types
  end
end
