package com.janrain.openid.consumer;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.janrain.yadis.Service;

/**
 * This class provides a container for information about the identity and server
 * being verified.
 * 
 * @author Janrain, Inc.
 */
public class OpenIDService implements Service, Serializable
{
    private static final long serialVersionUID = -8447354556218049438L;
    public static final String OPENID_1_0_NS = "http://openid.net/xmlns/1.0";
    public static final String OPENID_1_2_TYPE = "http://openid.net/signon/1.2";
    public static final String OPENID_1_1_TYPE = "http://openid.net/signon/1.1";
    public static final String OPENID_1_0_TYPE = "http://openid.net/signon/1.0";

    private static Set openidTypeUris = new HashSet();
    static
    {
        openidTypeUris.add(OPENID_1_0_TYPE);
        openidTypeUris.add(OPENID_1_1_TYPE);
        openidTypeUris.add(OPENID_1_2_TYPE);
    }

    private String identityUrl;
    private String serverUrl;
    private String delegate;

    private boolean fromYadis;
    private List typeUris;
    private int priority = Integer.MAX_VALUE;

    protected OpenIDService()
    {
        // empty for static factory methods
    }

    public OpenIDService(String identity, String delegate, String server,
                         boolean fromYadis, List typeUris, int priority)
    {
        identityUrl = identity;
        serverUrl = server;
        this.delegate = delegate;
        this.fromYadis = fromYadis;
        this.typeUris = typeUris;
        this.priority = priority;
    }

    public static OpenIDService fromHtml(String uri, String html)
    {
        OpenIDService result = new OpenIDService();

        result.identityUrl = uri;

        List linkAttrs = LinkParser.parseLinkAttrs(html);
        result.serverUrl = LinkParser.findFirstHref(linkAttrs, "openid.server");
        result.delegate = LinkParser
                .findFirstHref(linkAttrs, "openid.delegate");

        result.typeUris = new ArrayList();
        result.typeUris.add(OPENID_1_0_TYPE);
        return result;
    }

    /**
     * @return the identifier the server will be asked to confirm. This will not
     *         necessarily match the identifier the user is proving they own, so
     *         should not be used as their identifier
     */
    public String getDelegate()
    {
        return delegate == null ? identityUrl : delegate;
    }

    /**
     * @return the identifier the user is proving they own
     */
    public String getIdentityUrl()
    {
        return identityUrl;
    }

    /**
     * @return the Url of the identity server being asked about the identity
     */
    public String getServerUrl()
    {
        return serverUrl;
    }

    /**
     * @return a list of strings indicating what forms of OpenID the server
     *         provides, as well as extensions
     */
    public List getTypeUris()
    {
        return typeUris;
    }

    /**
     * @return true if this came from a Yadis discovery, false if it came from
     *         old-style OpenID discovery
     */
    public boolean isFromYadis()
    {
        return fromYadis;
    }

    protected void setDelegate(String delegate)
    {
        this.delegate = delegate;
    }

    protected void setFromYadis(boolean fromYadis)
    {
        this.fromYadis = fromYadis;
    }

    protected void setIdentityUrl(String identityUrl)
    {
        this.identityUrl = identityUrl;
    }

    protected void setServerUrl(String serverUrl)
    {
        this.serverUrl = serverUrl;
    }

    protected void setTypeUris(List typeUris)
    {
        this.typeUris = typeUris;
    }

    public static Set getOpenidTypeUris()
    {
        return Collections.unmodifiableSet(openidTypeUris);
    }

    public int compareTo(Object obj)
    {
        OpenIDService o = (OpenIDService)obj;
        if (priority > o.priority)
        {
            return 1;
        }
        else if (priority < o.priority)
        {
            return -1;
        }
        else
        {
            return 0;
        }
    }

}
