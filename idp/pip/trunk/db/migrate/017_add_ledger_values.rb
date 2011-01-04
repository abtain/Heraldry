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

class AddLedgerValues < ActiveRecord::Migration
  def self.up
    # trust related
    remove_column :trusts, :url
    
    # ledgers
    remove_column :ledgers, :updated_at
    remove_column :ledgers, :trust_id
    add_column :ledgers, :source, :string
    add_column :ledgers, :event, :string
    add_column :ledgers, :target, :string
    add_column :ledgers, :login, :string
    add_column :ledgers, :result, :string
    add_column :ledgers, :source_ip, :string
  end

  def self.down
    #trust related
    add_column :trusts, :url, :string

    #ledger stuff
    add_column :ledgers, :updated_at, :date
    add_column :ledgers, :trust_id, :integer
    remove_column :ledgers, :source
    remove_column :ledgers, :event
    remove_column :ledgers, :target
    remove_column :ledgers, :login
    remove_column :ledgers, :result
    remove_column :ledgers, :source_ip
  end
end