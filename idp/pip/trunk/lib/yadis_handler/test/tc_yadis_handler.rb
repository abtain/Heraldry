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

$: << '..'
APP_CONFIG = {:app_host => 'test.host'} unless defined? APP_CONFIG

unless defined? AppConfig
  class AppConfig
    def host
      APP_CONFIG[:app_host]
    end
  end
end

require 'test/tc_yadis_handler_util'
require 'yadis_handler'
require 'rexml/document'


class TestYadisHandler < HandlerTestCase
  @@mongrel_yadis_test_dir = 'test'

  
  def self.mongrel_yadis_test_dir=( mytd )
    @@mongrel_yadis_test_dir = mytd
  end

  def new_handler; Mongrel::Yadis::YadisHandler.new(BlackHole.new); end

  def test_simple_get
    sl = 'test.host:5000'
    uri = 'identity/admin'
    
    do_request

    assert_match %r[<head>.*<link rel="openid.server" href="http://#{sl}/server" />.*</head>]m, @response.body.string
    assert_match %r[<head>.*<meta http-equiv="X-XRDS-Location" content="http://#{sl}/#{uri}/yadis" />.*</head>]m, @response.body.string
    assert_match %r[<head>.*<meta http-equiv="X-YADIS-Location" content="http://#{sl}/#{uri}/yadis" />.*</head>]m, @response.body.string
  end

  def test_yadis_get_document
    do_request({'HTTP_ACCEPT' => 'application/xrds+xml'})
    assert_yadis_document
  end

  def test_yadis_get_document_by_path
    do_request('PATH_INFO' =>  '/admin/yadis')
    assert_yadis_document
  end

  def test_yadis_do_not_eat_extra
    do_request('PATH_INFO' => '/admin/bob')
    assert_equal '', @response.body.string
  end

  def assert_yadis_document
    assert_match %r[Content-Type: application/xrds\+xml], @response.header.out.string
    xml_body = @response.body.string
    
    assert_match %r[<Type>http://openid.net/signon/1.0</Type>], xml_body
    assert_match %r[<URI>http://test.host:5000/server</URI>], xml_body
    assert_match %r[<Type>http://openid.net/signon/1.1</Type>], xml_body
    
    File.open('temp.xml', 'w') { |f| f << xml_body }
    xmllint_result = `xmllint --schema #{ @@mongrel_yadis_test_dir }/xrds_schema.xml temp.xml 2>&1`
    assert_match /temp.xml validates/, xmllint_result

    xml = REXML::Document.new(xml_body)
    xrd = xml.root.elements[1]
    xrd.add_attributes('xmlns' => 'xri://$xrd*($v*2.0)', 
                       'xmlns:openid' => 'http://openid.net/xmlns/1.0')
    File.open('temp.xml', 'w') { |f| f << xrd.to_s }
    xmllint_result = `xmllint --schema #{ @@mongrel_yadis_test_dir }/xrd_schema.xml temp.xml 2>&1`
    assert_match /temp.xml validates/, xmllint_result
  end

  def do_request(args={})
    super({'PATH_INFO' => '/admin', 'SCRIPT_NAME' => '/identity'}.merge(args))
  end
end
