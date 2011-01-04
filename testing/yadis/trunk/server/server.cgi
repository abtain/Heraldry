#!/usr/bin/perl -w
use warnings;
use strict;
use CGI;

my $cgi = CGI->new();




my @services =
(
 # priority  type                                uri
 [       10, 'http://lid.netmesh.org/minimum-lid/2.0b8',    'http://mylid.net/example' ],
 [       20, 'http://lid.netmesh.org/sso/2.0b8',            'http://mylid.net/example' ],
 [       30, 'http://lid.netmesh.org/sso/1.0',              'http://mylid.net/example' ],
 );


sub PrintXMLResponse($$$$)
{
    my ($fh, $services, $xrdsns, $xrdns) = @_;
    my $xrdsnspre = '';
    my $xrdsnspost = '';
    my $xrdnspre = '';
    my $xrdnspost = '';

    if (defined($xrdsns) && $xrdsns ne '')
    {
	$xrdsnspre = "$xrdsns:";
	$xrdsnspost = ":$xrdsns";
    }
    if (defined($xrdns) && $xrdns ne '')
    {
	$xrdnspre = "$xrdns:";
	$xrdnspost = ":$xrdns";
    }

    print $fh '<?xml version="1.0" encoding="UTF-8"?>';
    print $fh "\n<${xrdsnspre}XRDS xmlns$xrdsnspost=\"xri://\$xrds\" xmlns$xrdnspost=\"xri://\$xrd*(\$v*2.0)\">\n";
    print $fh "\n    <${xrdnspre}XRD>\n";
    foreach (@$services)
    {
	print "    <${xrdnspre}Service priority=\"$_->[0]\">\n";
	print "      <${xrdnspre}Type>$_->[1]</${xrdnspre}Type>\n";
	print "      <${xrdnspre}URI>$_->[2]</${xrdnspre}URI>\n";
	print "    </${xrdnspre}Service>\n";
    }
    print $fh "    </${xrdnspre}XRD>\n";
    print $fh "</${xrdsnspre}XRDS>\n";
}


#     * SCRIPT_NAME: /~danlyke/yadisserve.cgi
#     * SERVER_NAME: localhost


my $thisURL = 'http://example/script.cgi';
$thisURL = "http://$ENV{'SERVER_NAME'}$ENV{'SCRIPT_NAME'}"
    if (defined($ENV{'SERVER_NAME'}) && defined($ENV{'SCRIPT_NAME'}));
my $yadisURL = "$thisURL?forcexml=1";

$yadisURL .= '&xrdsns='.$cgi->param('xrdsns')
    if (defined($cgi->param('xrdsns')));
$yadisURL .= '&xrdsns='.$cgi->param('xrdns')
    if (defined($cgi->param('xrdns')));

my $htmlResponse = <<EOF;
<html>
<head>
 <title>Yadis Test Server</title>
 <meta http-equiv="X-XRDS-Location" content="$yadisURL">
 <link rel="stylesheet" href="../conformance.css" type="text/css">
</head>
<body>
  <table>
   <tr>
    <td><h1>Yadis Test Server</h1></td>
    <td align="right"><a href="/"><img src="/customized/images/yadis-medium.png" alt="[Yadis logo]"></a></td>
   </tr>
  </table>

<p>This is a test server application for the <a href="http://yadis.org/">Yadis</a>
digital identity discovery
system. By passing this script various different options, you can
exercise all of the various code paths that your application uses to
discover Yadis resources.</p>

<p>You can alter the various responses that this application will give
you by appending parameters to the URL of this script,
<a href="$thisURL">$thisURL</a>.</p>

<dl>
<dt>omitheader</dt>
<dd>Force a response which does not
include the <code>X-XRDS-Location</code> response header, and requires
you to either parse the resulting HTML (in the case of an HTTP "GET"
command), or re-issue a different request (in the case of an HTTP
"HEAD" command).</dd>
<dt>forcexml</dt>

<dd>Respond with an example Yadis XRDS document, of type
<code>application/xrds+xml</code>.</dd>

<dt>xrdsns</dt>

<dd>Use the supplied value for the namespace of the 'xri://\$xrds'
namespace portions of the Yadis XRDS document. Defaults to 'xrds'.</dd>

<dt>xrdns</dt>

<dd>Use the supplied value for the namespace of the
    'xri://\$xrd*(\$v*2.0)' portions of the Yadis XRDS document. Defaults to '',
or no prefix.</dd>

</dl>

<p>So, for example, the Yadis spec
version 1.0, section 6.2.5 lays out the possible responses.</p>

<ol>

    <li>An HTML document with a &lt;head&gt; element that includes an
    &lt;meta&gt; element..., just use the HTTP "GET" method to <a
    href="$thisURL?omitheader=1">$thisURL?omitheader=1</a></li>

    <li>HTTP response-headers that include an X-XRDS-Location with a
    document, use an HTTP "GET" method and append nothing.</li>

    <li>HTTP response headers only, use an HTTP "HEAD" method with combinations of 
    
    <ol>
    <li>X-XRDS-Location header: <a href="$thisURL">$thisURL</a></li>
    <li>X-XRDS-Location header and an application/xrds+xml document type: <a
    href="$thisURL?forcexml=1">$thisURL?forcexml=1</a></li>
    <li>No X-XRDS-Location header and an application/xrds+xml document type: <a
    href="$thisURL?forcexml=1">$thisURL?forcexml=1&omitheader=1</a></li>
    </ol>

    <li>A document of MIME media type, application/xrds+xml, use an
    HTTP "GET" method on <a
    href="$thisURL?forcexml=1">$thisURL?forcexml=1</a></li>
</ol>

<p>In all cases right now, the Yadis XRDS document returned is from
version 1 of the specification, section 7.2 "A simple Yadis
document"</p>

</body>
</html>
EOF

# $cgi->request_method() - GET HEAD

# Force response:
# 1. An HTML document with appropriate <head><meta> fields
# 2. HTTP response-headers with X-XRDS-Location
# 3. HTTP response headers only
#    a. X-XRDS-Location response-header
#    b. content-type => application/xrds+xml,
# 4. content-type => application/rds+xml


my $requestMethod = $cgi->request_method;

$requestMethod = 'GET' unless defined($requestMethod);

my %headerArgs;
$headerArgs{-X_XRDS_Location} = $yadisURL
    unless $cgi->param('omitheader');

if ($requestMethod eq 'HEAD')
{
    if ($cgi->param('forcexml'))
    {
	$headerArgs{-type} = 'application/xrds+xml';
	print $cgi->header( \%headerArgs );
    }
    else
    {
	$headerArgs{-type} = 'text/html';
	print $cgi->header( \%headerArgs );
    }
}
elsif ($requestMethod eq 'GET')
{
    if ($cgi->param('forcexml'))
    {
	$headerArgs{-type} = 'application/xrds+xml';
	print $cgi->header( \%headerArgs );
	
	my $xrdsns = 'xrds';
	my $xrdns = '';
	$xrdsns = $cgi->param('xrdsns') if defined($cgi->param('xrdsns'));
	$xrdns = $cgi->param('xrdns') if defined($cgi->param('xrdns'));
       	PrintXMLResponse( \*STDOUT, \@services, $xrdsns, $xrdns );
    }
    else
    {
	$headerArgs{-type} = 'text/html';
	print $cgi->header( \%headerArgs );

	print $htmlResponse;
    }
}
else
{
    print $cgi->header('text/plain');
    print "Illegal request method $requestMethod\n";
}
