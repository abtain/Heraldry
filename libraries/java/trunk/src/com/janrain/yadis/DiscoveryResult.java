package com.janrain.yadis;

import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;

public class DiscoveryResult
{
    String requestUri;
    String normalizedUri;
    String xrdsUri;
    String contentType;
    String encoding;
    byte [] content;

    DiscoveryResult(String uri)
    {
        this.requestUri = uri;
    }

    public static DiscoveryResult fromURI(String uri) throws DiscoveryFailure
    {
        DiscoveryResult r = new DiscoveryResult(uri);

        HTTPFetcher f = HTTPFetcher.getFetcher();

        Map headers = new HashMap();
        headers.put("Accept:", Constants.ACCEPT_HEADER);
        FetchResponse resp = f.fetch(uri, headers);

        if (resp == null)
        {
            throw new DiscoveryFailure("Unable to retreive page");
        }

        if (resp.getStatusCode() != 200)
        {
            throw new DiscoveryFailure("HTTP response status was "
                    + resp.getStatusCode());
        }

        // Note the URL after following redirects
        r.normalizedUri = resp.getFinalUrl();

        // Attempt to find out if we already have the document
        r.contentType = (String)resp.getHeaders().get("content-type");

        String contentType = r.getContentType() == null ? "" : r
                .getContentType();
        contentType = contentType.split(";", 2)[0];

        if (Constants.CONTENT_TYPE.equalsIgnoreCase(contentType))
        {
            r.xrdsUri = r.getNormalizedUri();
        }
        else
        {
            // Try the header
            String yadisLocation = (String)resp.getHeaders().get(
                    Constants.HEADER_NAME.toLowerCase());

            if (yadisLocation == null)
            {
                yadisLocation = ParseHTML.findHTMLMeta(resp);
            }

            if (yadisLocation != null)
            {
                r.xrdsUri = yadisLocation;
                resp = f.fetch(yadisLocation);
                if (resp.getStatusCode() != 200)
                {
                    throw new DiscoveryFailure("HTTP response status was "
                            + resp.getStatusCode());
                }
                r.contentType = (String)resp.getHeaders().get("content-type");
                r.encoding = resp.getEncoding();
            }
        }

        r.content = resp.getRawContent();
        return r;
    }

    public boolean usedYadisLocation()
    {
        return normalizedUri.equals(xrdsUri);
    }

    public boolean isXRDS()
    {
        return usedYadisLocation()
                || Constants.CONTENT_TYPE.equals(contentType);
    }

    public byte [] getContent()
    {
        return content == null ? new byte[0] : content;
    }

    public String getDecodedContent()
    {
        try
        {
            return new String(getContent(), encoding == null ? "ISO8859-1"
                    : encoding);
        }
        catch (UnsupportedEncodingException e)
        {
            return "";
        }
    }

    public String getContentType()
    {
        return contentType;
    }

    public String getNormalizedUri()
    {
        return normalizedUri;
    }

    public String getRequestUri()
    {
        return requestUri;
    }

    public String getXrdsUri()
    {
        return xrdsUri;
    }

    public boolean equals(Object obj)
    {
        if (!(obj instanceof DiscoveryResult))
        {
            return false;
        }

        DiscoveryResult o = (DiscoveryResult)obj;
        if (requestUri == null ? o.requestUri != null : !requestUri
                .equals(o.requestUri))
        {
            return false;
        }

        if (normalizedUri == null ? o.normalizedUri != null : !normalizedUri
                .equals(o.normalizedUri))
        {
            return false;
        }

        if (xrdsUri == null ? o.xrdsUri != null : !xrdsUri.equals(o.xrdsUri))
        {
            return false;
        }

        if (encoding == null ? o.encoding == null : encoding.equals(o.encoding))
        {
            return Arrays.equals(getContent(), o.getContent());
        }
        else
        {
            try
            {
                return new String(getContent(), encoding).equals(new String(o
                        .getContent(), o.encoding));
            }
            catch (UnsupportedEncodingException e)
            {
                return Arrays.equals(getContent(), o.getContent());
            }
            catch (NullPointerException e)
            {
                return Arrays.equals(getContent(), o.getContent());
            }
        }
    }
}
