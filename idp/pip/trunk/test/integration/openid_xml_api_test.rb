require File.dirname(__FILE__) + '/../test_helper'

class OpenidXmlApiTest < ActionController::IntegrationTest
  fixtures :users, :profiles, :property_types, :properties, :profiles_properties, :trusts, :globalize_languages

  def test_checkid_immediate_with_no_trust_should_return_setup_url
    args = create_checkid('openid.mode' => 'checkid_immediate', 'access_profile' => 'openid')
    assert_nil Trust.find_by_trust_root(args['openid.trust_root'])

    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_response :success

    assert_match %r[<Response>.+</Response>]m, @response.body
    assert_mode 'id_res'
    assert_no_match %r[openid\.user_setup_url=], @response.body
    assert_not_nil assigns(:trust)
    assert !assigns(:trust).active?
  end

  def test_should_work_with_application_xml_content_type
    args = create_checkid('openid.mode' => 'checkid_immediate', 'access_profile' => 'openid')
    assert_nil Trust.find_by_trust_root(args['openid.trust_root'])

    post '/server/index', create_checkid_xml(args), :content_type => 'application/xml'
    assert_response :success

    assert_match %r[<Response>.+</Response>]m, @response.body
    assert_mode 'id_res'
    assert_no_match %r[openid\.user_setup_url=], @response.body
    assert_not_nil assigns(:trust)
    assert !assigns(:trust).active?
  end

  def test_checkid_immediate_xml_with_no_profile
    args = create_checkid('openid.mode' => 'checkid_immediate', 'access_profile' => '',
                          'openid.sreg.required' => 'nickname,email')
    assert_nil Trust.find_by_trust_root(args['openid.trust_root'])

    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>.+</Response>]m, @response.body
    assert_match %r[openid\.user_setup_url=], @response.body
    assert_nil assigns(:trust) 
  end

  def test_checkid_immediate_xml_with_sreg_bad_profile
    args = create_checkid('openid.mode' => 'checkid_immediate', 'access_profile' => 'shopping',
                          'openid.sreg.required' => 'nickname,email')
    assert_nil Trust.find_by_trust_root(args['openid.trust_root'])

    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>.+</Response>]m, @response.body
    assert_no_match %r[openid\.user_setup_url=], @response.body
    assert_not_nil assigns(:trust)
    assert !assigns(:trust).active?
  end  

  def test_checkid_immediate_xml_with_sreg
    args = create_checkid('openid.mode' => 'checkid_immediate', 'access_profile' => 'openid',
                          'openid.sreg.required' => 'nickname,email')
    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>.+</Response>]m, @response.body
    assert_match %r[openid\.sreg\.nickname=], @response.body
  end
 
  def test_checkid_setup_xml
    args = create_checkid('openid.mode' => 'checkid_setup', 'access_profile' => 'openid')
    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_xml_response
    assert_mode 'id_res'
  end
 
  def test_checkid_setup_xml_with_sreg
    args = create_checkid('openid.mode' => 'checkid_setup', 'access_profile' => 'openid',
                          'openid.sreg.required' => 'nickname,email')
    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_xml_response
    assert_mode 'id_res'
    assert_match %r[openid\.sreg\.nickname=], @response.body
  end
 
  def test_checkid_setup_xml_with_sreg_and_bad_profile
    args = create_checkid('openid.mode' => 'checkid_setup', 'access_profile' => 'shopping',
                          'openid.sreg.required' => 'nickname,email')
    assert_nil Trust.find_by_trust_root(args['openid.trust_root'])

    post '/server/index', create_checkid_xml(args), :content_type => 'text/xml'
    assert_xml_response
    assert_not_nil Trust.find_by_trust_root(args['openid.trust_root'])
    assert_mode 'id_res'
    assert_not_nil assigns(:trust)
    assert !assigns(:trust).active?  
  end
 
  def test_xml_post_with_no_data
    post '/server/index', '', :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>Error: bad xml</Response>]m, @response.body
  end
 
  def test_checkid_immediate_without_assoc_handle
    args = create_checkid('openid.mode' => 'checkid_immediate', 'access_profile' => 'openid')
    
    xml = <<-XML
      <OpenIDCheckID#{args['openid.mode'].split('_').last.capitalize}>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
        <Request>
          <Identity>#{args['openid.identity']}</Identity>
          <AccessProfile>#{args['access_profile']}</AccessProfile>
          #{create_sreg_xml(args)}
          <ReturnTo>#{args['openid.return_to']}</ReturnTo>
          <TrustRoot>#{args['openid.trust_root']}</TrustRoot>
        </Request>
      </OpenIDCheckID#{args['openid.mode'].split('_').last.capitalize}>
    XML
    post '/server/index', xml, :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>.+</Response>]m, @response.body 
    assert_mode 'id_res' 
    assert_no_match %r[openid\.user_setup_url=], @response.body 
    assert_not_nil assigns(:trust) 
    assert !assigns(:trust).active? 
  end 
	 	   
  def test_xml_delete_trust  
    xml = <<-XML 
     <DeleteTrust> 
       <User>#{users(:quentin).login}</User> 
       <Password>quentin</Password> 
       <TrustRoot>#{trusts(:amazon).trust_root}</TrustRoot> 
     </DeleteTrust> 
    XML

    assert_not_nil users(:quentin).trusts.find(:first, :conditions => "trust_root = '#{trusts(:amazon).trust_root}'") 
    post '/server/index', xml, :content_type => 'text/xml'
    assert_response :success 
    assert_match %r[<Response>success</Response>], @response.body 
    assert_nil users(:quentin).trusts.find(:first, :conditions => "trust_root = '#{trusts(:amazon).trust_root}'") 
  end 











  def test_xml_delete_trust_when_trust_does_not_exist
    xml = <<-XML
      <DeleteTrust>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
        <TrustRoot>http://nonexisting.net/</TrustRoot>
      </DeleteTrust>
    XML
    assert_nil users(:quentin).trusts.find(:first, :conditions => "trust_root = 'http://nonexisting.net'")
    post '/server/index', xml, :content_type => 'text/xml'
    assert_response :success
    assert_no_match %r[<Response>success</Response>], @response.body
  end
 
  def test_xml_delete_trust_bad_xml_format
    xml = <<-XML
      <DeleteTrust>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
        <Trust>http://nonexisting.net/</Trust>
      </DeleteTrust>
    XML
    post '/server/index', xml, :content_type => 'text/xml'
    assert_response :success
    assert_no_match %r[<Response>Error: bad xml request.</Response>], @response.body
    
  end
  
  def test_xml_create_trust
    xml = <<-XML
      <CreateTrust>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
        <Trust>
          <TrustRoot>http://localhost:2000/</TrustRoot>
          <Expires>-1</Expires>
          <AccessProfile>openid</AccessProfile>
        </Trust>
      </CreateTrust>
    XML
    
    post '/server/index', xml, :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>success</Response>], @response.body
    assert Trust.find_by_trust_root('http://localhost:2000/')
  end
 
  def test_xml_create_trust_with_expiration_date
    xml = <<-XML
      <CreateTrust>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
        <Trust>
          <TrustRoot>http://localhost:2000/</TrustRoot>
          <Expires>04/05/2007</Expires>
          <AccessProfile>openid</AccessProfile>
        </Trust>
      </CreateTrust>
    XML
    
    post '/server/index', xml, :content_type => 'text/xml'
    assert_response :success
    assert_match %r[<Response>success</Response>], @response.body
    assert_not_nil Trust.find_by_trust_root('http://localhost:2000/')
    assert_not_nil Trust.find_by_trust_root('http://localhost:2000/').expires_at
  end
 
  def test_query_profile_list
    xml = <<-XML
      <QueryProfileList>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
      </QueryProfileList>
    XML
    
    post '/server/index', xml, :content_type => 'text/xml'
    assert_xml_response
  end
 
  def test_query_profile
    xml = <<-XML
      <QueryProfile>
        <User>#{users(:quentin).login}</User>
        <Password>quentin</Password>
        <AccessProfile>openid</AccessProfile>
      </QueryProfile>
    XML
      
    post '/server/index', xml, :content_type => 'text/xml'
    assert_xml_response
  end

###### Helper methods #############################

  def assert_mode(mode)
    assert_match %r[openid\.mode=#{mode}], @response.body
  end

  def assert_xml_response
    assert_response :success
    assert_match %r[<Response>.+</Response>]m, @response.body
  end

  def create_checkid(args={})
    {"openid.return_to"=>"http://localhost:2000/complete", 
      "openid.mode"=>"checkid_setup", 
      "openid.identity"=>"http://test.host/user/quentin", 
      "openid.trust_root"=>"http://localhost:2000/", 
      "openid.assoc_handle"=>"{HMAC-SHA1}{44327c5d}{EVAnng==}"}.merge(args)
  end
  
  def create_checkid_xml(args={})
    xml = <<-XML
        <OpenIDCheckID#{args['openid.mode'].split('_').last.capitalize}>
          <User>#{users(:quentin).login}</User>
          <Password>quentin</Password>
          <Request>
            <Identity>#{args['openid.identity']}</Identity>
            <AssocHandle></AssocHandle>
            <AccessProfile>#{args['access_profile']}</AccessProfile>
            #{create_sreg_xml(args)}
            <ReturnTo>#{args['openid.return_to']}</ReturnTo>
            <TrustRoot>#{args['openid.trust_root']}</TrustRoot>
          </Request>
        </OpenIDCheckID#{args['openid.mode'].split('_').last.capitalize}>
      XML
  end

  def create_sreg_xml(args)
    if args['openid.sreg.required'] || args['openid.sreg.optional']
      "<Sreg required=\"#{args['openid.sreg.required']}\" optional=\"#{args['openid.sreg.optional']}\" policy_url=\"\" />"
    else
      ""
    end
  end
end
