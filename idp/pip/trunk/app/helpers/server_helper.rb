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

# Methods added to this module are available to ServerController views.
module ServerHelper
  
  # Creates a group of hidden input fields that are used by javascript
  # to properly highlight fields that are included in TrustProfiles.
  def hidden_fields_for_highlighting
    current_user.profiles.map do |p|
      "<input type=\"hidden\" id=\"profile_#{p.id}_properties\"" +
      " value=\"#{p.properties.map{|prop| prop.id}.join(',')}\" />"
    end.join("\n")
  end
  
  # Displays text informing the user that a consumer site requests specific properties
  # if _properties_ is not nil or an empty Array. Otherwise, it informs the user that 
  # no profile information is requested.
  #
  # All output is enclosed in <p> tags.
  #
  # properties:: An array of Properties or nil.
  def text_for_user_notification(properties)
    unless properties && properties.empty?
      <<-EOS
    <p><b><span class="colored">To complete the registration process the site is requesting additional information. Please select a trust profile you would like to associate the site with or create a new one. The Trust Profile you select will determine the information that is shared.</span></b></p>
    <p style="font-style: italic;">Fields marked with an asterisk (*) are required for successful registration with this site.</p>
      EOS
    else
      <<-EOS
      <p><b><span class="colored">Please select a Trust Profile you would like
      to associate the site with or create a new one.  This site is not requesting
      any additonal profile information from you.</span></b></p>
      EOS
    end
  end
end