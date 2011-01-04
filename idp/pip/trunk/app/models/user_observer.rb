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

# UserObserver is used by AccountController to observe the User model for
# the purposes of sending signup_notification and activation_notification
# to the user.
class UserObserver < ActiveRecord::Observer
  # Cause UserNotifier to send an email to the user for verifying their email address.
  def after_create(user)
    UserNotifier.deliver_signup_notification(user)
  end

  # Cause UserNotifier to send an email to the user after they verify their email address.
  def after_save(user)
    UserNotifier.deliver_activation(user) if user.recently_activated?
  end
end
