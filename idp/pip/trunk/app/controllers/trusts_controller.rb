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

# For management of Trusts that a user has.
class TrustsController < ApplicationController
  # List the existing trusts for _current_user_.
  # ====params
  # order_by:: Specifies which column to sort by.  Allowed values are 'trusts.title', 
  #              'trusts.trust_root', 'profiles.title', and 'trusts.expires_at'
  # order:: Specifies sort order (A-Z or Z-A).  Allowed values are 'asc' and 'desc'
  # page:: Number specifing the current page number.
  def list
    allow_sort_params = ['trusts.title', 'trusts.trust_root', 'profiles.title', 'trusts.expires_at']
    @order_by = params[:order_by] && allow_sort_params.include?(params[:order_by].downcase) ? params[:order_by] : 'trusts.created_at'
    @order = params[:order] && ['asc', 'desc'].include?(params[:order].downcase) ? params[:order] : 'DESC'
    @trust_pages, @trusts = paginate_collection current_user.trusts.find(:all, :include => :profile, :order => @order_by + ' ' + @order), {:per_page => 10, :page => params[:page]}
  end
  
  # Destroy the given Trust.
  # ====params
  # id:: Profile#id
  def destroy
    @trust = current_user.trusts.find(params[:id])
    @trust.destroy       
    respond_to do |type|
      type.html { redirect_to :action => 'list' }
      type.js   { render }
    end
  end
end
