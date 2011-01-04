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

require 'rubygems'
require 'gem_plugin'
require 'mongrel'

class YadisHandler < GemPlugin::Plugin "/commands"
  include Mongrel::Command::Base

  def configure
    options []
  end

  def run
    require 'yadis_handler'

    server = Mongrel::HttpServer.new('0.0.0.0', 3002)
    server.register('/yadis', Mongrel::Yadis::YadisHandler.new)
    puts "Your server is now running at http://0.0.0.0:3002/yadis"
    if RUBY_PLATFORM !~ /mswin/
      trap("INT") { 
        $server.stop 
      }
      puts "Use CTRL-C to quit."
    else
      puts "Use CTRL-Pause/Break to quit."
    end

    server.run.join
  end
end
