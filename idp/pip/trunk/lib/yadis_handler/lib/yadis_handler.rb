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
require 'mongrel'

module Mongrel
  module Yadis
    class YadisHandler < Mongrel::HttpHandler
      @@protocol = APP_CONFIG[:ssl_disabled] ? 'http' : 'https'
      def initialize(logger=nil)
        @logger = logger || Logger.new('log/development.log')
      end

      def split_path_info(path_info)
        path_info[1..-1].split('/')
      end

      def yadis_request?(request)
        (request.params['HTTP_ACCEPT'] && request.params['HTTP_ACCEPT'].include?('application/xrds+xml')) ||
          (split_path_info(request.params['PATH_INFO'])[1] == 'yadis')
      end

      def self.yadis_document_for(user, host, uri)
#        @logger.info "****** yadis_document_for #{host}/#{uri}/#{user} ********"
        <<-EOL
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
  xmlns:xrds="xri://$xrds"
  xmlns:openid="http://openid.net/xmlns/1.0"  
  xmlns="xri://$xrd*($v*2.0)">
  <XRD>

    <Service priority="10">
      <Type>http://openid.net/signon/1.1</Type>
      <Type>http://openid.net/sreg/1.0</Type>
      <URI>#{@@protocol}://#{host}/server</URI>
    </Service>

    <Service priority="20">
      <Type>http://openid.net/signon/1.0</Type>
      <Type>http://openid.net/sreg/1.0</Type>
      <URI>#{@@protocol}://#{host}/server</URI>
    </Service>

  </XRD>
</xrds:XRDS>
EOL
      end

      def identity_document_for(user, host, uri)
        @logger.info "****** identity_document_for #{host}/#{uri}/#{user} ********"
        <<-EOL
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <link rel="openid.server" href="#{@@protocol}://#{host}/server" />
    <meta http-equiv="X-XRDS-Location" content="http://#{host}/#{uri}/#{user}/yadis" />
    <meta http-equiv="X-YADIS-Location" content="http://#{host}/#{uri}/#{user}/yadis" />
    <title>Identity Endpoint For #{user}</title>
  </head>
  <body>
    <p>This is an identity endpoint for #{user}</p>
  </body>
</html>
EOL
      end
      
      def host_with_port(request)
        if forwarded = request.params["HTTP_X_FORWARDED_HOST"]
          forwarded.split(/,\s?/).last
        elsif http_host = request.params['HTTP_HOST']
          http_host
        elsif server_name = request.params['SERVER_NAME']
          server_name
        else
          "#{request.params['SERVER_ADDR']}:#{request.params['SERVER_PORT']}"
        end
      end

      def host(request)
        hwp = host_with_port(request)
        if hwp =~ /:\d+$/
          $`
        else
          hwp
        end
      end
      
      def port(request)
        if host_with_port(request) =~ /:(\d+)$/
          return $1
        end
        return nil
      end

      def process(request, response)
        @logger.info "****** NEW HIT ********"
        @logger.info request.inspect
        user, extra = split_path_info(request.params['PATH_INFO'])
        host = AppConfig.host(host(request)) + (port(request) ? ':' + port(request) : '')
        uri = request.params['SCRIPT_NAME'][1..-1]

        if yadis_request?(request)
          response.start(200) do |head, out|
            head['Content-Type'] = 'application/xrds+xml'
            head['X-XRDS-Location'] = "#{@@protocol}://#{host}/#{uri}/#{user}/yadis"
            head['X-YADIS-Location'] = "#{@@protocol}://#{host}/#{uri}/#{user}/yadis"
            out << YadisHandler.yadis_document_for(user, host, uri)
          end
        elsif extra.nil?
          response.start(200) do |head, out|
            head['Content-Type'] = 'text/html; charset=UTF-8'
	          head['X-XRDS-Location'] = "#{@@protocol}://#{host}/#{uri}/#{user}/yadis"
            head['X-YADIS-Location'] = "#{@@protocol}://#{host}/#{uri}/#{user}/yadis"
	          out << identity_document_for(user, host, uri)
          end
        end
        @logger.info response.inspect
      end
    end
  end
end

if __FILE__ == $0
  server = Mongrel::HttpServer.new('0.0.0.0', 3002)
  server.register('/yadis', Mongrel::Yadis::YadisHandler.new)
  puts 'Your server is now running at http://0.0.0.0:3002/yadis'
  puts 'Use CTRL-C to quit'
  server.run.join
end
