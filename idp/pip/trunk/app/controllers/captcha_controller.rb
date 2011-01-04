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
# CaptchaController is responsible for returning a captcha image
# to be displayed on user signup.
#
# == Requirements
# Does not require SSL or login.
class CaptchaController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :ssl_required
  
  # Returns a captcha image to display.
  # The captcha code will be saved in session['captcha_code'].
  # ====Example
  # Call this method from your views using <img src="/captcha/new">.
  def new
    create_captcha_image
    prevent_caching
    return send_file(@captcha.filename, :file_name => 'captcha_image', 
                     :type => 'image/png', :disposition => 'inline')
  end

private
  def create_captcha_image
    @captcha = IdpCaptcha.new
    @captcha.generate
    @session['captcha_code'] = @captcha.code
  end

  def prevent_caching
    response.headers['Expires'] = '0'
    response.headers['Cache-Control'] = 'max-age=0'
  end
end
