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

# ActionMailer class for sending notification emails to the user.
class UserNotifier < ActionMailer::Base
  
  # Creates and sends a signup notification email to the _user's_ email address.
  # ====Parameters
  # user:: The User to whom we are sending the email.
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://#{AppConfig.host}/account/activate/#{user.activation_code}"
  end

  # Creates and sends a password reset email to the _user's_ email address.
  # This email allows the user to return to the app and set a new password without first logging
  # in with their current password.
  # ====Parameters
  # user:: The User to whom we are sending the email.
  def password_reset(user)
    setup_email(user)
    @subject    += 'Reset your password'
    @body[:url]  = "http://#{AppConfig.host}/account/reset_password/#{user.activation_code}"
  end

  # Creates and sends an email to the _user's_ email address when their account is activated.
  # ====Parameters
  # user:: The User to whom we are sending the email.  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://#{AppConfig.host}/"
  end
  
  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = APP_CONFIG[:reply_email]
    @subject     = "[#{AppConfig.host}] "
    @sent_on     = Time.now
    @body[:user] = user
  end
end
