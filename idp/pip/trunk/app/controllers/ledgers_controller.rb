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

# == About
# LedgersController is responsible for displaying account activity
# to the user.
#
# == Requirements
# SSL and login are required on all actions.
class LedgersController < ApplicationController
  # Alias for list.
  def index
    list
    render :action => 'list' unless performed?
  end

  # Show all activity for the _current_user_, most recent first.
  def list
    @ledger_pages, @ledgers = paginate :ledgers, :conditions => ['user_id = ?', current_user.id], :order => 'created_at desc', :per_page => 10
  end
end
