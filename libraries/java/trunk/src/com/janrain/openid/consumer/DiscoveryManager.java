package com.janrain.openid.consumer;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.logging.Logger;

import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;
import com.janrain.yadis.DiscoveryFailure;
import com.janrain.yadis.DiscoveryResult;
import com.janrain.yadis.ServiceParser;
import com.janrain.yadis.XRDS;
import com.janrain.yadis.XRDSError;

/**
 * This class provides the consumer library with the logic to find a list of
 * OpenID services for a URL.
 * 
 * @author JanRain, Inc.
 */
public class DiscoveryManager implements Serializable
{
    private static final long serialVersionUID = 2406514388629284823L;

    private static final String cls = "com.janrain.openid.consumer.DiscoveryManager";
    private static final Logger logger = Logger.getLogger(cls);

    private List services = new ArrayList();
    private int index;

    private static class OpenIDServiceParser implements ServiceParser
    {
        private String yadisUrl;

        public OpenIDServiceParser(String yadisUrl)
        {
            this.yadisUrl = yadisUrl;
        }

        public Set getSupportedTypes()
        {
            return OpenIDService.getOpenidTypeUris();
        }

        private static String getContent(Node n)
        {
            NodeList text = n.getChildNodes();
            for (int i = 0; i < text.getLength(); i++)
            {
                Node t = text.item(i);
                if (t.getNodeType() == Node.TEXT_NODE)
                {
                    return t.getNodeValue().trim();
                }
            }

            return "";
        }

        public List parseService(Node n)
        {
            List result = new ArrayList();

            List types = new ArrayList();
            String delegate = yadisUrl;

            NodeList nl = n.getChildNodes();

            for (int i = 0; i < nl.getLength(); i++)
            {
                Node child = nl.item(i);
                if (child.getNodeType() == Node.ELEMENT_NODE)
                {
                    String ns = child.getNamespaceURI();
                    String name = child.getLocalName();

                    if (XRDS.XRDNS.equals(ns) && name.equals("Type"))
                    {
                        types.add(getContent(child));
                    }
                    else if (OpenIDService.OPENID_1_0_NS.equals(ns)
                            && name.equals("Delegate"))
                    {
                        delegate = getContent(child);
                    }
                }
            }

            for (int i = 0; i < nl.getLength(); i++)
            {
                Node child = nl.item(i);
                if (child.getNodeType() == Node.ELEMENT_NODE
                        && XRDS.XRDNS.equals(child.getNamespaceURI())
                        && child.getLocalName().equals("URI"))
                {
                    int p = Integer.MAX_VALUE;
                    String uri = getContent(child);
                    NamedNodeMap attrs = child.getAttributes();

                    Node priority = attrs.getNamedItem("priority");
                    if (priority != null)
                    {
                        try
                        {
                            p = Integer.parseInt(priority.getNodeValue());
                        }
                        catch (NumberFormatException e)
                        {
                            // ignore, nothing to do
                        }
                    }

                    result.add(new OpenIDService(yadisUrl, delegate, uri, true,
                            types, p));
                }
            }

            Collections.sort(result);
            return result;
        }

    }

    public DiscoveryManager(String url)
    {
        DiscoveryResult response;
        try
        {
            response = DiscoveryResult.fromURI(url);
        }
        catch (DiscoveryFailure df)
        {
            // no fallback case here.
            logger.warning("Unable to get a DiscoveryResult for " + url);
            return;
        }

        String identityUrl = response.getNormalizedUri();

        try
        {
            services = new XRDS(response).getServices(new OpenIDServiceParser(
                    identityUrl));
        }
        catch (XRDSError e)
        {
            // do nothing
        }

        if (services.size() == 0)
        {
            String body;
            if (response.isXRDS())
            {
                FetchResponse fr = HTTPFetcher.getFetcher().fetch(url);
                identityUrl = fr.getFinalUrl();
                body = fr.getContent();
            }
            else
            {
                body = response.getDecodedContent();
            }

            OpenIDService s = OpenIDService.fromHtml(identityUrl, body);
            if (s.getServerUrl() != null)
            {
                services.add(s);
            }
        }
    }

    public boolean isEmpty()
    {
        return services.size() == 0;
    }

    public int size()
    {
        return services.size();
    }

    public boolean hasNext()
    {
        return index < services.size();
    }

    public OpenIDService getNext()
    {
        return (OpenIDService)services.get(index++);
    }
}
