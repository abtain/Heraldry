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

# Helper methods for AccountController views
module AccountHelper
  # Retrieves the User's login from the identity url in the openid headers if possible.
  # Returns nil if the identity url is not properly formatted or there is no idenity url.
  def default_value_for_login
    if login = get_login_from_query_string
      return (user = User.find_by_login(login)) ? user.login : login
    else
      return nil
    end
  end
  
  def yadis_header_content
    login = account_subdomain.gsub(/\./, '_')
    content_for 'header' do
      <<-EOS
        <link rel="openid.server" href="http://#{host_with_port}/server" />
        <meta http-equiv="X-XRDS-Location" content="http://#{host_with_port }/user/#{login}/yadis" />
        <meta http-equiv="X-YADIS-Location" content="http://#{host_with_port }/user/#{login}/yadis" />
      EOS
    end
  end

  def using_subdomain?
    account_subdomain && account_subdomain != 'www'
  end
private
  def get_login_from_query_string
    if @return_to_query && CGI::unescape(@return_to_query) =~ /openid.\identity=(.*?)&/
      get_login_from_url($1)
    else
      return nil
    end
  end

  def get_login_from_url(url)
    if (url =~ %r[http://(([\w-]+\.){0,2}[\w-]+)\.#{host_with_port}]) || (url =~ %r[/user/(([\w-]+\.){0,2}[\w-]+)]) 
      $1.gsub(/_/, '.')
    elsif (login = get_login_from_domain(url))
      login
    else
      nil
    end
  end

  def get_login_from_domain(url)
    url =~ %r[https?://(([\w-]+\.){0,2}[\w-]+)]
    login = $1
    if url && login && APP_CONFIG[:restricted_names].include?(login.split('.').last)
      login
    else
      nil
    end
  end
end
