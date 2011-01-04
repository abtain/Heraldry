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

require 'test/test_helper_lib/ror_spider'
require 'test/test_helper'

class SecurityTest < ActionController::IntegrationTest
  include OpenIdTestMethods

  fixtures :avatars, :ledgers, :profiles, :profiles_properties,
           :properties, :property_types, :trusts, :users

  @@forms = {
    '/account/profile' => {
      :display_pages => %w(
        /account/profile /profiles/edit/1 /profiles/edit/2 /profiles/edit/3
        /profiles/edit/4
      )
    },
    '/profiles/edit/1' => { :display_pages => %w( /profiles ) },
    '/profiles/new' => { :display_pages => %w( /profiles ) },
    '/account/edit' => {
      :display_pages => %w( /account/edit ), :inputs => %w( user[email] )
    },
  }
  
  # Examples from http://ha.ckers.org/xss.html
  @@xss_examples = [
    '<SCRIPT SRC=http://www.eastmedia.com/xss.js></SCRIPT>',
    '<IMG SRC="javascript:alert(\'XSS\');">',
    '<IMG SRC=javascript:alert(\'XSS\')>',
    '<IMG SRC=JaVaScRiPt:alert(\'XSS\')>',
    '<IMG SRC=javascript:alert(&quot;XSS&quot;)>',
    '<IMG SRC=`javascript:alert("RSnake says, \'XSS\'")`>',
    '<IMG """><SCRIPT>alert("XSS")</SCRIPT>">',
    '<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>',
    '<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>',
    '<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>',
    '<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>',
    '<IMG SRC="jav&#x09;ascript:alert(\'XSS\');">',
    '<IMG SRC="jav&#x0A;ascript:alert(\'XSS\');">',
    '<IMG SRC="jav&#x0D;ascript:alert(\'XSS\');">',
    '<IMG SRC=" &#14;  javascript:alert(\'XSS\');">',
    '<SCRIPT/XSS SRC="http://www.eastmedia.com/xss.js"></SCRIPT>',
    '<<SCRIPT>alert("XSS");//<</SCRIPT>',
    '<SCRIPT SRC=http://www.eastmedia.com/xss.js?<B>',
    '<IMG SRC="javascript:alert(\'XSS\')"',
    "<SCRIPT>a=/XSS/\nalert(a.source)</SCRIPT>",
    '\";alert(\'XSS\');//',
    '<INPUT TYPE="IMAGE" SRC="javascript:alert(\'XSS\');">',
    '<BODY BACKGROUND="javascript:alert(\'XSS\')">',
    '<BODY ONLOAD=alert(\'XSS\')>'
  ]
  
  def assert_no_client_xss( verboten, args )
    bad_checkid = create_checkid args
    post '/server', bad_checkid
    follow_redirect! if @response.code == '302'
    assert_no_match( verboten, @response.body )
  end
  
  def assert_no_xss( display_page )
    get display_page
    @@xss_examples.each do |xss_example|
      assert_no_match(
        Regexp.new( Regexp.escape( xss_example ) ), @response.body
      )
    end
  end
  
  def each_form( body, form_info )
    body.find_all( :tag => 'form' ).each do |form_tag|
      action = form_tag.attributes['action']
      inputs = ( form_info[:inputs] or FormInputs.new form_tag )
      yield( action, inputs )
    end
  end
  
  def form_test( form_url, form_info )
    get form_url
    body = HTML::Document.new @response.body
    each_form( body, form_info ) do |action, inputs|
      xss_post( action, inputs )
    end
    form_info[:display_pages].each do |display_page|
      assert_no_xss display_page
    end
    each_form( body, form_info ) do |action, inputs|
      sql_inject_post( action, inputs )
    end
  end
  
  def sql_inject_post( action, inputs )
    sql_inject_args = {}
    inputs.each do |input|
      sql_inject_args[input] = "x'; delete from users where id = 1; --"
    end
    post( action, sql_inject_args )
    User.find 1
  end
  
  def test_bad_client_xss
    get '/account/login'
    post '/account/login', :login => 'quentin', :password => 'quentin'
    follow_redirect!
    xss = '<IMG SRC="javascript:alert(\'XSS\');">'
    verboten = Regexp.new( Regexp.escape( xss ) )
    assert_no_client_xss(
      verboten, 'openid.trust_root' => xss, 'openid.identity' => xss
    )
    assert_no_client_xss(
      verboten,
      'openid.trust_root' => "http://localhost:2000/#{ xss }",
      'openid.identity' => "http://test.host/user/quentin#{ xss }"
    )
  end
  
  def test_no_form_xss
    get '/account/login'
    post '/account/login', :login => 'quentin', :password => 'quentin'
    follow_redirect!
    @@forms.each do |form_url, form_info| form_test( form_url, form_info ); end
  end
  
  def xss_post( action, inputs )
    xss_args = {}
    inputs.each do |input|
      xss_args[input.to_sym] = @@xss_examples[rand(@@xss_examples.size)]
    end
    post( action, xss_args )
  end
  
  class FormInputs < Array
    def initialize( form_tag )
      super()
      parse form_tag
    end
    
    def parse( tag )
      if tag.respond_to?( :name ) and %w( input select ).include?( tag.name )
        unless %w( file image ).include? tag.attributes['type'] or
               tag.attributes['readonly'] == 'readonly'
          self << tag.attributes['name']
        end
      else
        tag.children.each do |subtag| parse( subtag ); end
      end
    end
  end
end

