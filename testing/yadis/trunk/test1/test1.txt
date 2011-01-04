#!/usr/bin/perl -w
use warnings;
use strict;

use CGI;
use LWP;
use XML::Parser;
use HTML::Parser;

my $cgi = new CGI;


sub handle_YadisXML_start
{
    my ($p, $tag, %attrs) = @_;
    my $vars = $p->{-YADISvars};

    my $attrs = \%attrs;
    my ($k,$v, $nsdefined);
    my $xmlns = $vars->{-xmlns}->[$#{$vars->{-xmlns}}];
    while (($k, $v) = each %$attrs)
    {
	my ($ns, $nsv);
	if ($k eq 'xmlns')
	{
	    $ns = '';
	    $nsv = $v;
	}
	elsif (substr($k, 0, 6) eq 'xmlns:')
	{
	    $ns = substr($k, 6).":";
	    $nsv = $v;
	}
	if (defined($nsv)
	    && (defined(
			{ 'xri://$xrds' => 1,
			  'xri://$xrd*($v*2.0)' => 1 }->{$nsv})))
	{
	    if (defined($nsdefined))
	    {
		my %xmlns = %$xmlns;
		push @{$vars->{-xmlns}}, \%xmlns;
		$xmlns= \%xmlns;
	    }
	    $vars->{-namespaces}->{$nsv} = $ns;
	    $xmlns->{$nsv} = $ns;
	}
    }
    push @{$vars->{-nsstack}}, $nsdefined;
    my $tagstack = $vars->{-tagstack};
    
    if ($tag eq "$xmlns->{'xri://$xrds'}XRDS")
    {
	push @{$vars->{-errors}}, "$tag in unexpected place, expected at top level"
	    if ($#$tagstack >= 0);
    }
    elsif ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}XRD")
    {
	push @{$vars->{-errors}},
	"$tag in unexpected place, expected in <$xmlns->{'xri://$xrds'}XRDS> block"
	    if ($tagstack->[$#$tagstack] ne "$xmlns->{'xri://$xrds'}XRDS");
    }
    elsif ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}Service")
    {
	my $priority = $attrs->{"$xmlns->{'xri://$xrd*($v*2.0)'}priority"};
	if (!defined($priority))
	{
	    # Assume namespace of the parent
	    $priority = $attrs->{'priority'};
	}
	$vars->{-lastPriority} = $priority;
	$vars->{-lastType} = [];
	$vars->{-lastURI} = [];
	push @{$vars->{-errors}},
	"$tag in unexpected place, expected in <$xmlns->{'xri://$xrd*($v*2.0)'}XRD> block"
	    if ($tagstack->[$#$tagstack] ne "$xmlns->{'xri://$xrd*($v*2.0)'}XRD");
    }
    elsif ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}Type")
    {
	$vars->{-text} = '';
	push @{$vars->{-errors}},
	"$tag in unexpected place, expected in <$xmlns->{'xri://$xrd*($v*2.0)'}Service> block"
	    if ($tagstack->[$#$tagstack] ne "$xmlns->{'xri://$xrd*($v*2.0)'}Service");
    }
    elsif ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}URI")
    {
	$vars->{-text} = '';
	push @{$vars->{-errors}},
	"$tag in unexpected place, expected in <$xmlns->{'xri://$xrd*($v*2.0)'}Service> block"
	    if ($tagstack->[$#$tagstack] ne "$xmlns->{'xri://$xrd*($v*2.0)'}Service");
    }
    elsif ($tag =~ /^(.*\:)?(Service|Type|URI)$/)
    {
	push @{$vars->{-errors}},
	"'$tag' found in unexpected namespace '$1', expected in namespace for 'xri://\$xrd*(\$v*2.0)' which is $xmlns->{'xri://$xrd*($v*2.0)'}";
    }
    push @$tagstack, $tag;
}
sub handle_YadisXML_end
{
    my ($p, $tag) = @_;
    my $vars = $p->{-YADISvars};
    my $tagstack = $vars->{-tagstack};
    my $xmlns = $vars->{-xmlns}->[$#{$vars->{-xmlns}}];

    pop @$tagstack;
    if ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}Service")
    {
	push @{$vars->{-results}},
	[
	 $vars->{-lastPriority},
	 $vars->{-lastType},
	 $vars->{-lastURI}
	 ];
	undef $vars->{-priority};
    }
    elsif ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}Type")
    {
	push @{$vars->{-lastType}}, $vars->{-text};
    }
    elsif ($tag eq "$xmlns->{'xri://$xrd*($v*2.0)'}URI")
    {
	push @{$vars->{-lastURI}}, $vars->{-text};
    }
    pop @{$vars->{-xmlns}} if (pop @{$vars->{-nsstack}});
}

sub handle_YadisXML_char
{
    my ($p, $text) = @_;
    my $vars = $p->{-YADISvars};
    $vars->{-text} .= $text;
}

sub StartHTMLTag()
{
    my ($p, $tag, $attrs) = @_;

    $p->{-YADIS_locals} = {} unless defined ($p->{-YADIS_locals});
    my $locals = $p->{-YADIS_locals};
    $locals->{-YADIS_in_head} = 1 if ($tag eq 'head');

    my $headtagfound; # if we found and responded to a tag that should only be in the <head>

    if ($tag eq 'link')
    {
	if (defined($attrs->{'rel'}))
	{
	    if (lc($attrs->{'rel'}) eq 'openid.server')
	    {
		push @{$p->{-OPENIDlocations}}, [$attrs->{'href'}, undef, undef];
		$headtagfound = 1;
	    }
	}
    }
    elsif ($tag eq 'meta')
    {
	if (defined($attrs->{'http-equiv'}))
	{
	    if (lc($attrs->{'http-equiv'}) eq 'x-xrds-location')
	    {
		push @{$p->{-YADISlocations}}, [$attrs->{'content'}, 'body', 'x-rds-location'];
	    }
	} # end of if we have an http-equiv attribute
    } # end of tag meta

    if ($headtagfound)
    {
	print "    found outside HTML head section\n"
	    unless $locals->{-YADIS_in_head};
    }
}

sub EndHTMLTag()
{
    my ($p, $tag ) = @_;
    my $locals = $p->{-YADIS_locals};

    $locals->{-YADIS_in_head} = 0 if ($tag eq 'head');
}

# The CGI lib seems to sometimes return arrays instead of single values for HTTP content types.
# This routine provides a comparison function for it.
sub contentTypeIs($$)
{
    my ($contentType, $requiredMime) = @_;

    if( ref( $contentType ) eq "ARRAY" )
    {
        foreach( @{$contentType} )
        {
            if( substr($_, 0, length($requiredMime)) eq $requiredMime )
            {
                return 1;
            }
        }
        return 0;
    }
    else
    {
        return substr($contentType, 0, length($requiredMime)) eq $requiredMime;
    }
}


# GetYadisXMLDocURLsFromResponse
#
# Look through a response and retrieve the YADIS XML Document from
# a respones to an LWP::UserAgent->get(...) operation.
#
# $method    - string, either 'GET' or 'HEAD'
# $hadheader - whether or not the header included an Accept:... for
#              the YADIS type
# $response  - the response from the LWP::UserAgent->get(...)
# $yadisurl  - the URL we tried to retrieve this from
# $yadisURLs - a reference to an array of returned values

sub GetYadisXMLDocURLsFromResponse($$$$$)
{
    my ($method, $hadheader, $response, $yadisurl, $yadisXMLDocURLs) = @_;

    my $yadisXMLDocURL = $response->headers->{'x-xrds-location'};

    if (defined($yadisXMLDocURL))
    {
	print "<br><strong>Found header: $yadisXMLDocURL $yadisurl</strong><br>";
	if (ref($yadisXMLDocURL) eq 'ARRAY')
	{
	    push @$yadisXMLDocURLs, [$yadisXMLDocURL->[0], 'X-XRDS-Location header (array)'];
	}
	else
	{
	    push @$yadisXMLDocURLs, [$yadisXMLDocURL, 'X-XRDS-Location header (non-array)'];
	}
    }
    if ( contentTypeIs( $response->headers->{'content-type'}, 'text/html' ))
    {
	if ($method eq 'HEAD')
	{
	}
	elsif (!$response->content)
	{
	}
	else
	{
	    my $head = $1;
	    
	    my $p = HTML::Parser->new( api_version => 3,
				       start_h => [\&StartHTMLTag, 'self, tagname, attr' ],
				       end_h => [\&EndHTMLTag, 'self, tagname' ] );
	    $p->{-OPENIDlocations} = [];
	    $p->{-YADISlocations} = [];
	    $p->parse($response->content);
	    foreach (@{$p->{-YADISlocations}})
	    {
		push @$yadisXMLDocURLs, $_;
	    }
	}
    }
    elsif ( contentTypeIs( $response->headers->{'content-type'}, 'application/xrds+xml' ))
    {
	push @$yadisXMLDocURLs, [$yadisurl, 'content-type', undef]
    }
    else
    {
	my $err  = "The response for HTTP method '$method' had neither the HTML nor XRDS+XML mime types. (was: '";
           $err .= $response->headers->{'content-type'};
           $err .= "')\n";
	print "<p><strong>Warning:</strong> $err</p>\n";
	return $err;
    }
    return undef;
}

print $cgi->header();

print <<EOF;
<html>
<head>
 <title>Yadis Test Client</title>
 <link rel="stylesheet" href="../conformance.css" type="text/css" />
</head>
<body>
  <table>
   <tr>
    <td><h1>Yadis Test Client</h1></td>
    <td align="right"><a href="/"><img src="/customized/images/yadis-medium.png" alt="[Yadis logo]"></a></td>
   </tr>
  </table>

<p>Given a <a href="http://www.yadis.org/">Yadis</a> URL, this program
attempts to give diagnostic information about the various ways in
which it can discover the eventual URL for the Yadis XRDS document.</p>
<p>You must enter fully-qualified URLs; e.g. <tt>http://example.com/</tt>
   instead of just <tt>example.com</tt>.</p>
EOF


if ($cgi->param('url'))
{
    my $yadisurl = $cgi->param('url');
    my $escapedyadisurl = $cgi->escapeHTML($yadisurl);
    print "<h2>Report for: <a href=\"$escapedyadisurl\">$escapedyadisurl</a></h2>\n";
    my $ua = LWP::UserAgent->new( parse_head => 0 );
    $ua->agent('Yadistest/0.00');
    $ua->protocols_allowed( ['http', 'https'] );

    my @accept = ('text/html');

    my $response;
    my $err;

    my @yadisDocURLsHeadNone;
    $response = $ua->head( $yadisurl, Accept => \@accept );
    $err = GetYadisXMLDocURLsFromResponse('HEAD', 0, $response,
					  $yadisurl, \@yadisDocURLsHeadNone);

    my @yadisDocURLsGetNone;
    $response = $ua->get( $yadisurl, Accept => \@accept );
    $err = GetYadisXMLDocURLsFromResponse('GET', 0, $response,
					  $yadisurl, \@yadisDocURLsGetNone);

    push @accept, 'application/xrds+xml';

    my @yadisDocURLsHeadRds;
    $response = $ua->head( $yadisurl, Accept => \@accept);
    $err = GetYadisXMLDocURLsFromResponse('HEAD', 1, $response,
					  $yadisurl, \@yadisDocURLsHeadRds );

    my @yadisDocURLsGetRds;
    $response = $ua->get( $yadisurl, Accept => \@accept );
    $err = GetYadisXMLDocURLsFromResponse('GET', 1, $response,
					  $yadisurl, \@yadisDocURLsGetRds );

    my $yadisDocURL;
    my $yadisDocURLsource;
    my @yadisDocURLsources;
    my $url;

    foreach $url (@yadisDocURLsHeadNone)
    {
	if (defined($yadisDocURL))
	{
	    if ($yadisDocURL ne $url->[0])
	    {
		print "<p><strong>Warning:</strong> URL was previously"
		    ." defined as "
		    .$cgi->escapeHTML($yadisDocURL)
		    ." by $yadisDocURLsource, "
		    ." is now ".$cgi->escapeHTML($url->[0])."</p>\n";
	    }
	}

	$yadisDocURLsource = 'HTTP "HEAD" method without '.
	    "<code>Accept: application/xrds+xml</code> header from $url->[1]";

	$yadisDocURL = $url->[0];
	push @yadisDocURLsources, $yadisDocURLsource;
    }
    foreach $url (@yadisDocURLsGetNone)
    {
	if (defined($yadisDocURL))
	{
	    if ($yadisDocURL ne $url->[0])
	    {
		print "<p><strong>Warning:</strong> URL was previously"
		    ." defined as "
		    .$cgi->escapeHTML($yadisDocURL)
		    ." by $yadisDocURLsource, "
		    ." is now ".$cgi->escapeHTML($url->[0])."</p>\n";
	    }
	}

	$yadisDocURLsource = 'HTTP "GET" method without '.
	    "<code>Accept: application/xrds+xml</code> header from $url->[1]";

	$yadisDocURL = $url->[0];
	push @yadisDocURLsources, $yadisDocURLsource;
    }
    foreach $url (@yadisDocURLsHeadRds)
    {
	if (defined($yadisDocURL))
	{
	    if ($yadisDocURL ne $url->[0])
	    {
		print "<p><strong>Warning:</strong> URL was previously"
		    ." defined as "
		    .$cgi->escapeHTML($yadisDocURL)
		    ." by $yadisDocURLsource, "
		    ." is now ".$cgi->escapeHTML($url->[0])."</p>\n";
	    }
	}

	$yadisDocURLsource = 'HTTP "HEAD" method <em>with</em> '.
	    "<code>Accept: application/xrds+xml</code> header from $url->[1]";

	$yadisDocURL = $url->[0];
	push @yadisDocURLsources, $yadisDocURLsource;
    }
    foreach $url (@yadisDocURLsGetRds)
    {
	if (defined($yadisDocURL))
	{
	    if ($yadisDocURL ne $url->[0])
	    {
		print "<p><strong>Warning:</strong> URL was previously"
		    ." defined as "
		    .$cgi->escapeHTML($yadisDocURL)
		    ." by $yadisDocURLsource, "
		    ." is now ".$cgi->escapeHTML($url->[0])."</p>\n";
	    }
	}

	$yadisDocURLsource = 'HTTP "GET" method <em>with</em> '.
	    "<code>Accept: application/xrds+xml</code> header from $url->[1]";

	$yadisDocURL = $url->[0];
	push @yadisDocURLsources, $yadisDocURLsource;
    }

    if (defined($yadisDocURL))
    {
	print '<p>derived '
	    .$cgi->escapeHTML($yadisDocURL)." from:</p>\n<ul>\n";
	foreach my $source (@yadisDocURLsources)
	{
	    print "  <li>$source</li>\n";
	}
	print "</ul>\n";

	print "<h2>Retrieving Yadis XRDS document</h2>\n";
	$response = $ua->get( $yadisDocURL, Accept => \@accept );

	if ($response->is_success)
	{
	    my $p = XML::Parser->new((Handlers => {Start => \&handle_YadisXML_start,
						   End   => \&handle_YadisXML_end,
						   Char  => \&handle_YadisXML_char}));
	    my %vars =
		(
		 -text => '',
		 -tagstack => [],
		 -errors => [],
		 -xmlns => [{}],
		 -namespaces => {},
		 -nsstack => [],
		 -results => [],
		 );
	    
	    $p->{-YADISvars} = \%vars;
	    if (eval {$p->parse($response->content)})
	    {
		if (!defined($response->headers->{'vary'})
		    && $yadisurl eq $yadisDocURL)
		{
		    push @{$vars{-errors}}, "Response lacks 'Vary:' header, necessary when theXRDS  document URL and the discovery URL are the same";
		}
		if ($vars{-namespaces}->{'xri://$xrds'} ne 'xrds:')
		{
		    push @{$vars{-errors}}, "The namespace for 'xri:://\$xrds' is '$vars{-namespaces}->{'xri://$xrds'}'. Although this is legal, the sample document in the space uses 'xrds:', and consumers without proper namespace support may be confused.";
		}
		if (defined($vars{-namespaces}->{'xri://$xrd*($v*2.0)'})
		    && $vars{-namespaces}->{'xri://$xrd*($v*2.0)'} ne '')
		{
		    push @{$vars{-errors}}, "The namespace for 'xri://\$xrd*(\$v*2.0)' is '$vars{-namespaces}->{'xri://$xrd*($v*2.0)'}', the sample document uses none, and consumers without proper namespace support may be confused.";
		}
		if (@{$vars{-errors}})
		{
		    print "<h3>Errors & Warnings:</h3>\n<ul>";
		    foreach (@{$vars{-errors}})
		    {
			print "<li>$_</li>\n";
		    }
		    print "</ul>";
		}
		print "<h3>Yadis Services</h3>\n";
		my @results = sort
		{
		    if (defined($a->[0]) && $a->[0] =~ /^[0-9]+$/)
		    {
			if (defined($b->[0]) && $b->[0] =~ /^[0-9]+$/)
			{
			    return $a->[0] <=> $b->[0];
			}
			else
			{
			    return -1;
			}
		    }
		    else
		    {
			return 1;
		    }
		} @{$vars{-results}};
		
		print '<table border="1">';
		print '<tr><th>Priority</th><th>Type(s)</th><th>URI</th><th>Note</th></tr>';
		
		foreach (@results)
		{
		    my ($priority, $types, $uris) = @{$_};
		    my $error = '';
		    if (defined($priority))
		    {
			$error = 'invalid priority'
			    unless ($priority =~ /^[0-9]+$/);
		    }
		    else
		    {
			$priority = '<undef>';
		    }
		    
		    print "<tr><td>$priority</td>";
		    print '<td>'.join('<br />', map {$cgi->escapeHTML($_)} @$types).'</td>';
		    print '<td>'.join('<br />', map {$cgi->escapeHTML($_)} @$uris).'</td>';
			print '<td>';
			print $cgi->escapeHTML($error);
			print '</td>';
		    print "</tr>\n";
		}
		print "</table>\n";
	    }
	    else
	    {
		print '<p><strong>Error:</strong> parsing of document failed with:</p>';
		print "\n<blockquote>".$cgi->escapeHTML($@)."</blockquote>\n";
	    }
	}
	else
	{
	    print '<p><strong>Error:</strong> Unable to retrieve Yadis'
		.' XRDS document from '.$cgi->escapeHTML($yadisDocURL)."</p>\n";
	}
    }
    else
    {
	print '<p><strong>Error:</strong> Unable to locate Yadis XRDS document from '
	    .$escapedyadisurl."</p>\n";
    }
    print "<p>&nbsp;</p>\n";
}


print $cgi->start_form( -method=>'GET' );
print 'Yadis URL:&nbsp;';
print $cgi->textfield(-name=>'url', -size=>50 );
print $cgi->submit();
print $cgi->end_form;

print "\n</body>\n</html>\n";

