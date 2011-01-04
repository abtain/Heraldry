package com.janrain.yadis;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

public class XRDS
{
    public static final String XRDNS = "xri://$xrd*($v*2.0)";

    private Document doc;

    /**
     * @param res
     * @throws XRDSError
     */
    public XRDS(DiscoveryResult res) throws XRDSError
    {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setCoalescing(true);
        dbf.setIgnoringComments(true);
        dbf.setNamespaceAware(true);
        dbf.setValidating(false);

        DocumentBuilder db;
        try
        {
            db = dbf.newDocumentBuilder();
        }
        catch (ParserConfigurationException e)
        {
            throw new RuntimeException("oops");
        }

        try
        {
            doc = db.parse(new ByteArrayInputStream(res.getContent()));
        }
        catch (IOException e)
        {
            throw new XRDSError(e);
        }
        catch (SAXException e)
        {
            throw new XRDSError(e);
        }
    }

    /**
     * @param s
     * @return
     */
    public List getServices(ServiceParser s)
    {
        List wrapped = new ArrayList();

        NodeList services = doc.getElementsByTagNameNS(XRDNS, "Service");
        for (int i = 0; i < services.getLength(); i++)
        {
            Node service = services.item(i);
            NamedNodeMap attrs = service.getAttributes();
            int p = Integer.MAX_VALUE;
            Node priority = attrs.getNamedItem("priority");
            if (priority != null)
            {
                try
                {
                    p = Integer.parseInt(priority.getNodeValue());
                }
                catch (NumberFormatException e)
                {
                    // nothing to do
                }
            }

            NodeList children = service.getChildNodes();
            for (int j = 0; j < children.getLength(); j++)
            {
                Node child = children.item(j);
                if (child.getNodeType() == Node.ELEMENT_NODE
                        && child.getNamespaceURI().equals(XRDNS)
                        && child.getLocalName().equals("Type")
                        && s.getSupportedTypes().contains(
                                child.getLastChild().getNodeValue()))
                {
                    List parsed = s.parseService(service);
                    Iterator it = parsed.iterator();
                    while (it.hasNext())
                    {
                        wrapped.add(new ServiceWrapper(p, (Service)it.next()));
                    }
                    break;
                }
            }
        }

        Collections.sort(wrapped);
        List result = new ArrayList();

        Iterator it = wrapped.iterator();
        while (it.hasNext())
        {
            ServiceWrapper w = (ServiceWrapper)it.next();
            result.add(w.s);
        }
        return result;
    }

    private static class ServiceWrapper implements Comparable
    {
        private int priority;
        Service s;

        public ServiceWrapper(int priority, Service s)
        {
            this.priority = priority;
            this.s = s;
        }

        public int compareTo(Object obj)
        {
            ServiceWrapper o = (ServiceWrapper)obj;
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
}
