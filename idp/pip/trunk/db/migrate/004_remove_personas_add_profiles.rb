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

class Persona < ActiveRecord::Base; end
class RemovePersonasAddProfiles < ActiveRecord::Migration
  def self.up
    create_table "profiles", :force => true do |t|
      t.column "user_id", :integer
      t.column "name", :string
      t.column "description", :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    
    Persona.find(:all).each do |persona|
      Profile.create \
        :user_id      => persona.user_id,
        :name         => persona.name,
        :description  => persona.description,
        :created_at   => persona.created_at,
        :updated_at   => persona.updated_at
    end
    
    drop_table :personas
    
    remove_column :properties, :name
  end

  def self.down
    create_table "personas", :force => true do |t|
      t.column "user_id", :integer
      t.column "name", :string
      t.column "description", :text
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    Profile.find(:all).each do |profile|
      Persona.create \
        :user_id      => profile.user_id,
        :name         => profile.name,
        :description  => profile.description,
        :created_at   => profile.created_at,
        :updated_at   => profile.updated_at
    end
    
    drop_table :profiles
    
    add_column :properties, :name, :string
    
  end
end
