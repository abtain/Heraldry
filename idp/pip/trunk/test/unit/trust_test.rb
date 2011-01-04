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

require File.dirname(__FILE__) + '/../test_helper'

class TrustTest < Test::Unit::TestCase
  fixtures :trusts, :profiles

  def test_requires_profile
    t = create_trust(:expires_at => 3.months.from_now)
    assert t.errors.on(:profile_id)
  end
  
  def test_never_expires
    t = create_trust(:profile => profiles(:work))
    assert t.save
    assert t.never_expires?
    assert t.active?
  end
  
  def test_should_create_trust
    t = create_trust(:profile => profiles(:work), :expires_at => 3.months.from_now )
    assert t.valid?
  end
  
  protected
  def create_trust(options={})
    Trust.create({:trust_root => 'http://eastmedia.com', :title => 'EastMedia' }.merge(options))
  end
end
