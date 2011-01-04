package com.janrain.openid.consumer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import junit.framework.TestCase;

import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;

public class DiscoveryManagerTest extends TestCase
{
    static Map allDocs;
    static
    {
        allDocs = new HashMap();
        InputStream is = null;
        try
        {
            is = DiscoveryManagerTest.class
                    .getResourceAsStream("discoverydata.txt");
            if (is == null)
            {
                fail("Unable to load test data");
            }

            InputStreamReader ir = new InputStreamReader(is, "UTF-8");
            BufferedReader br = new BufferedReader(ir);

            char [] chunk = new char[1024];
            StringBuffer sb = new StringBuffer();

            for (int l = br.read(chunk); l >= 0; l = br.read(chunk))
            {
                sb.append(chunk, 0, l);
            }

            String input = sb.toString();
            String [] pages = input.split("\n\n\n");
            for (int i = 0; i < pages.length; i++)
            {
                String [] parts = pages[i].split("\n", 2);
                allDocs.put(parts[0], parts[1]);
            }
        }
        catch (IOException e)
        {
            fail("This shouldn't have happened");
        }
        finally
        {
            if (is != null)
            {
                try
                {
                    is.close();
                }
                catch (IOException e)
                {
                    // nothing to do
                }
            }
        }

    }

    static class DiscoveryFetcher extends HTTPFetcher
    {
        Map documents;
        List fetchlog = new ArrayList();
        String redirect;

        public DiscoveryFetcher(Map documents)
        {
            this.documents = documents;
        }

        public FetchResponse fetch(String url, String body, Map headers)
        {
            fetchlog.add(new Object[] {url, body, headers});
            String finalUrl = redirect == null ? url : redirect;

            String [] o = (String [])documents.get(url);
            int status = 200;
            if (o == null)
            {
                status = 404;
                o = new String[] {"text/plain", ""};
            }
            headers = new HashMap();
            headers.put("content-type", o[0]);

            try
            {
                byte [] bytes = o[1].getBytes("UTF-8");
                return new FetchResponse(status, finalUrl, bytes, "UTF-8",
                        headers);
            }
            catch (UnsupportedEncodingException e)
            {
                // still won't happen
                return null;
            }
        }
    }

    private HTTPFetcher old;
    private String idUrl = "http://someuser.unittest/";
    private DiscoveryFetcher fetcher;
    private Map documents;

    protected void setUp() throws Exception
    {
        old = HTTPFetcher.getFetcher();
        documents = new HashMap();
        fetcher = new DiscoveryFetcher(documents);
        HTTPFetcher.setFetcher(fetcher);
    }

    protected void tearDown() throws Exception
    {
        HTTPFetcher.setFetcher(old);
        fetcher = null;
    }

    private void usedYadis(OpenIDService s)
    {
        assertTrue("Expected to use Yadis", s.isFromYadis());
    }

    private void notUsedYadis(OpenIDService s)
    {
        assertTrue("Expected to use old-style discover", !s.isFromYadis());
    }

    public void test404()
    {
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertTrue(dm.isEmpty());
    }

    public void testNoYadis()
    {
        documents.put(idUrl, new String[] {"text/html",
                (String)allDocs.get("openid_html")});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertEquals(1, dm.size());
        OpenIDService s = dm.getNext();
        assertEquals(idUrl, s.getIdentityUrl());
        assertEquals("http://www.myopenid.com/server", s.getServerUrl());
        assertEquals("http://smoker.myopenid.com/", s.getDelegate());
        notUsedYadis(s);
    }

    public void testNoOpenID()
    {
        documents.put(idUrl, new String[] {"text/plain", "junk"});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertTrue(dm.isEmpty());
    }

    public void testYadis()
    {
        documents.put(idUrl, new String[] {"application/xrds+xml",
                (String)allDocs.get("yadis_2entries")});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertEquals(2, dm.size());

        OpenIDService s1 = dm.getNext();
        assertEquals(idUrl, s1.getIdentityUrl());
        assertEquals("http://www.myopenid.com/server", s1.getServerUrl());
        usedYadis(s1);

        OpenIDService s2 = dm.getNext();
        assertEquals(idUrl, s2.getIdentityUrl());
        assertEquals("http://www.livejournal.com/openid/server.bml", s2
                .getServerUrl());

        usedYadis(s2);
    }

    public void testRedirect()
    {
        String expectedFinalUrl = "http://elsewhere.unittest/";
        fetcher.redirect = expectedFinalUrl;

        documents.put(idUrl, new String[] {"text/html",
                (String)allDocs.get("openid_html")});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertEquals(1, dm.size());
        OpenIDService s = dm.getNext();
        assertEquals(expectedFinalUrl, s.getIdentityUrl());
        assertEquals("http://www.myopenid.com/server", s.getServerUrl());
        assertEquals("http://smoker.myopenid.com/", s.getDelegate());
        notUsedYadis(s);
    }

    public void testEmptyList()
    {
        documents.put(idUrl, new String[] {"application/xrds+xml",
                (String)allDocs.get("yadis_0entries")});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertTrue(dm.isEmpty());
    }

    public void testEmptyListWithLegacy()
    {
        documents.put(idUrl, new String[] {"text/html",
                (String)allDocs.get("openid_and_yadis_html")});

        documents.put(idUrl + "xrds", new String[] {"application/xrds+xml",
                (String)allDocs.get("yadis_0entries")});

        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertEquals(1, dm.size());
        OpenIDService s = dm.getNext();
        assertEquals(idUrl, s.getIdentityUrl());
        assertEquals("http://www.myopenid.com/server", s.getServerUrl());
        notUsedYadis(s);
    }

    public void testYadisNoDelegate()
    {
        documents.put(idUrl, new String[] {"application/xrds+xml",
                (String)allDocs.get("yadis_no_delegate")});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertEquals(1, dm.size());
        OpenIDService s = dm.getNext();
        assertEquals(idUrl, s.getIdentityUrl());
        assertEquals(idUrl, s.getDelegate());
        assertEquals("http://www.myopenid.com/server", s.getServerUrl());
        usedYadis(s);
    }

    public void testOpenIDNoDelegate()
    {
        documents.put(idUrl, new String[] {"text/html",
                (String)allDocs.get("openid_html_no_delegate")});
        DiscoveryManager dm = new DiscoveryManager(idUrl);
        assertEquals(1, dm.size());
        OpenIDService s = dm.getNext();
        assertEquals(idUrl, s.getIdentityUrl());
        assertEquals(idUrl, s.getDelegate());
        assertEquals("http://www.myopenid.com/server", s.getServerUrl());
        notUsedYadis(s);
    }
}
