/*
 * OpenIDConsumerTest.java JUnit based test Created on February 27, 2006, 3:35
 * PM
 */

package com.janrain.openid.consumer;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLDecoder;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;
import java.util.logging.ConsoleHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

import com.janrain.openid.Association;
import com.janrain.openid.DiffieHellman;
import com.janrain.openid.Util;
import com.janrain.openid.store.MemoryStore;
import com.janrain.openid.store.OpenIDStore;
import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;

/**
 * @author JanRain, Inc.
 */
public class ConsumerTest extends TestCase
{
    private static Logger debug = Logger
            .getLogger("com.janrain.openid.consumer");

    String serverUrl = "http://server.example.com/";
    String consumerUrl = "http://consumer.example.com/";
    byte [] secret0;
    byte [] secret1;
    String handle0;
    String handle1;

    public ConsumerTest(String testName)
    {
        super(testName);
    }

    protected void setUp() throws Exception
    {
        secret0 = "another 20-byte key.".getBytes("UTF-8");
        secret1 = new byte[20];

        handle0 = "Snarky";
        handle1 = "Zeroes";

        debug.setLevel(Level.OFF);

        Handler [] handlers = debug.getHandlers();
        for (int i = 0; i < handlers.length; i++)
        {
            debug.removeHandler(handlers[i]);
        }

        Handler h = new ConsoleHandler();
        h.setLevel(Level.ALL);
        debug.addHandler(h);
    }

    public static Test suite()
    {
        TestSuite suite = new TestSuite();

        suite.addTestSuite(ConsumerTest.class);
        suite.addTestSuite(SetupNeededTest.class);
        suite.addTestSuite(CheckAuthTriggeredTest.class);

        return suite;
    }

    private Map parse(String query)
    {
        Map result = new HashMap();
        String [] args = query.split("&");

        try
        {
            for (int i = 0; i < args.length; i++)
            {
                String [] kv = args[i].split("=");
                String k = URLDecoder.decode(kv[0], "UTF-8");
                String v = URLDecoder.decode(kv[1], "UTF-8");
                if (result.put(k, v) != null)
                {
                    fail("Key " + k + " used twice");
                }
            }
        }
        catch (UnsupportedEncodingException e)
        {
            // will never happen
            throw new RuntimeException(e);
        }

        return result;
    }

    private static FetchResponse build(int code, String url, String data)
    {
        Map h = new HashMap();
        String encoding = "UTF-8";
        try
        {
            return new FetchResponse(code, url, data.getBytes(encoding),
                    encoding, h);
        }
        catch (UnsupportedEncodingException e)
        {
            // this won't happen
            return null;
        }
    }

    private class TestFetcher extends HTTPFetcher
    {
        private String userUrl;
        private String userPage;
        private byte [] secret;
        private String handle;
        public int numAssocs = 0;

        public TestFetcher(String userUrl, String userPage, byte [] secret,
                           String handle)
        {
            this.userUrl = userUrl;
            this.userPage = userPage;
            this.secret = secret;
            this.handle = handle;
        }

        public FetchResponse fetch(String url, String data, Map headers)
        {
            if (data == null)
            {
                if (url.equals(userUrl))
                {
                    return build(200, url, userPage);
                }
                else
                {
                    return build(404, url, "Not Found");
                }
            }
            else
            {
                if (data.indexOf("openid.mode=associate") < 0)
                {
                    return build(400, url, "error:bad request\r\n");
                }

                Map query = parse(data);

                assertTrue(query.size() == 4 || query.size() == 6);
                assertEquals("associate", query.get("openid.mode"));
                assertEquals("HMAC-SHA1", query.get("openid.assoc_type"));
                assertEquals("DH-SHA1", query.get("openid.session_type"));

                DiffieHellman d = new DiffieHellman((String)query
                        .get("openid.dh_modulus"), (String)query
                        .get("openid.dh_gen"));

                BigInteger cpub = Util.base64ToNumber((String)query
                        .get("openid.dh_consumer_public"));

                String encMacKey = Util.toBase64(d.xorSecret(cpub, secret));

                Map reply = new HashMap();
                reply.put("assoc_type", "HMAC-SHA1");
                reply.put("assoc_handle", handle);
                reply.put("expires_in", "600");
                reply.put("session_type", "DH-SHA1");
                reply.put("dh_server_public", Util.numberToBase64(d
                        .getPublicKey()));
                reply.put("enc_mac_key", encMacKey);

                numAssocs++;

                return build(200, url, Util.toKVForm(null, reply));
            }
        }
    }

    private String createUserPage(String links)
    {
        return "<html>\r\n" + "  <head>\r\n"
                + "    <title>A user page</title>\r\n" + "    " + links
                + "\r\n" + "  </head>\r\n" + "  <body>\r\n"
                + "    blah blah\r\n" + "  </body>\r\n" + "</html>\r\n";
    }

    public void checkSuccess(final String userUrl, final String delegateUrl,
            String links, final boolean immediate)
    {
        final Map session = new HashMap();
        final MemoryStore store = new MemoryStore();
        final String mode = immediate ? "checkid_immediate" : "checkid_setup";

        final String userPage = createUserPage(links);

        HTTPFetcher old = HTTPFetcher.getFetcher();
        TestFetcher fetcher = new TestFetcher(userUrl, userPage, secret0,
                handle0);
        HTTPFetcher.setFetcher(fetcher);

        final Consumer consumer = new Consumer(session, store);

        Runnable t = new Runnable()
        {
            public void run()
            {
                AuthRequest a;
                try
                {
                    a = consumer.begin(userUrl);
                }
                catch (IOException e)
                {
                    throw new RuntimeException(e);
                }

                String redirect = a.redirectUrl(consumerUrl, consumerUrl,
                        immediate);
                try
                {
                    Map expected = new HashMap();
                    expected.put("openid.mode", mode);
                    expected.put("openid.identity", delegateUrl);
                    expected.put("openid.trust_root", consumerUrl);
                    expected.put("openid.assoc_handle", handle0);

                    Map actual = parse(new URL(redirect).getQuery());
                    String rt = (String)actual.remove("openid.return_to");
                    actual.remove(Consumer.getNonceName());

                    assertEquals(new TreeMap(expected), new TreeMap(actual));
                    assertTrue(rt.startsWith(consumerUrl));
                }
                catch (MalformedURLException e)
                {
                    throw new RuntimeException(e);
                }

                assertTrue(redirect.startsWith(serverUrl));

                Map query = new HashMap();
                query.put("openid.mode", "id_res");
                query.put("openid.return_to", Util.appendArgs(consumerUrl, a
                        .getReturnToArgs()));
                query.put("openid.identity", delegateUrl);
                query.put("openid.assoc_handle", handle0);
                query.putAll(a.getReturnToArgs());

                Association assoc = store.getAssociation(serverUrl, handle0);
                assertNotNull(assoc);
                assoc.signMap(Arrays.asList(new String[] {"mode", "return_to",
                        "identity"}), query);

                Response b = consumer.complete(query);
                assertEquals(StatusCode.SUCCESS, b.getStatus());
                assertEquals(userUrl, ((SuccessResponse)b).getIdentityUrl());
            }
        };

        assertEquals(0, fetcher.numAssocs);
        t.run();
        assertEquals(1, fetcher.numAssocs);

        // Test that doing it again uses the existing association
        t.run();
        assertEquals(1, fetcher.numAssocs);

        // Another association is created if we remove the existing one
        store.removeAssociation(serverUrl, handle0);
        t.run();
        assertEquals(2, fetcher.numAssocs);

        // Test that doing it again uses the existing association
        t.run();
        assertEquals(2, fetcher.numAssocs);

        // restore old fetcher
        HTTPFetcher.setFetcher(old);
    }

    public void testSuccess()
    {
        String userUrl = "http://www.example.com/user.html";
        String links = "<link rel=\"openid.server\" href=\"" + serverUrl
                + "\" />";

        String delegateUrl = "http://consumer.example.com/user";
        String delegateLinks = "<link rel=\"openid.server\" href=\""
                + serverUrl + "\" /> <link rel=\"openid.delegate\" href=\""
                + delegateUrl + "\" />";

        checkSuccess(userUrl, userUrl, links, false);
        checkSuccess(userUrl, userUrl, links, true);

        checkSuccess(userUrl, delegateUrl, delegateLinks, false);
        checkSuccess(userUrl, delegateUrl, delegateLinks, true);
    }

    private class FailingFetcher extends HTTPFetcher
    {
        public FetchResponse fetch(String url, String data, Map headers)
        {
            try
            {
                String [] pieces = url.split("/");
                int status = Integer.parseInt(pieces[pieces.length - 1]);
                return build(status, url, "");
            }
            catch (Exception e)
            {
                return null;
            }
        }
    }

    public void testBadFetch()
    {
        OpenIDStore store = new MemoryStore();
        HTTPFetcher old = HTTPFetcher.getFetcher();

        HTTPFetcher fetcher = new FailingFetcher();
        HTTPFetcher.setFetcher(fetcher);
        Map session = new HashMap();
        Consumer consumer = new Consumer(session, store);

        String [] cases = {"http://network.error/error",
                "http://not.found/404", "http://bad.request/400",
                "http://server.error/500"};

        for (int i = 0; i < cases.length; i++)
        {
            try
            {
                consumer.begin(cases[i]);
                fail("Didn't get an IOException on a case that couldn't fetch");
            }
            catch (IOException e)
            {
                // expected
            }
        }

        HTTPFetcher.setFetcher(old);
    }

    public void testBadParse()
    {
        OpenIDStore store = new MemoryStore();
        String userUrl = "http://user.example.com/";
        String [] cases = {"", "http://not.in.a.link.tag/",
                "<link rel=\"openid.server\" href=\"not.in.html.or.head\" />"};

        for (int i = 0; i < cases.length; i++)
        {
            HTTPFetcher old = HTTPFetcher.getFetcher();
            TestFetcher f = new TestFetcher(userUrl, cases[i], null, null);
            HTTPFetcher.setFetcher(f);
            Map session = new HashMap();

            Consumer consumer = new Consumer(session, store);

            try
            {
                consumer.begin(userUrl);
                fail("Didn't get an IOException on a case that couldn't parse");
            }
            catch (IOException e)
            {
                // expected
            }

            HTTPFetcher.setFetcher(old);
        }
    }

    private static class CheckAuthHappened extends RuntimeException
    {
        private static final long serialVersionUID = -2195970999996174596L;
    }

    private static class ExceptingFetcher extends HTTPFetcher
    {
        public FetchResponse fetch(String url, String data, Map headers)
        {
            if (data != null)
            {
                throw new CheckAuthHappened();
            }
            else
            {
                return null;
            }
        }
    }

    public static class IdResBase extends TestCase
    {
        private HTTPFetcher old;
        public HTTPFetcher fetcher = new ExceptingFetcher();
        public String nonce = "nonny";
        public String returnTo = "http://return.to/?" + Consumer.getNonceName()
                + "=" + nonce;
        public String serverId = "sirod";
        public String serverUrl = "serlie";
        public String consumerId = "consu";
        public OpenIDStore store;
        public Consumer consumer;

        public IdResBase(String testName)
        {
            super(testName);
        }

        protected void setUp() throws Exception
        {
            old = HTTPFetcher.getFetcher();
            HTTPFetcher.setFetcher(fetcher);
            Map session = new HashMap();
            store = new MemoryStore();
            consumer = new Consumer(session, store);

            Token t = new Token(store.getAuthKey(), consumerId, serverId,
                    serverUrl);
            session.put("_openid_consumer_last_token", t);
        }

        protected void tearDown() throws Exception
        {
            HTTPFetcher.setFetcher(old);
        }
    }

    public static class SetupNeededTest extends IdResBase
    {
        public SetupNeededTest(String testName)
        {
            super(testName);
        }

        public void testSetupNeeded()
        {
            String setupUrl = "http://unittest/setup-here";
            Map query = new HashMap();
            query.put("openid.mode", "id_res");
            query.put("openid.user_setup_url", setupUrl);

            Response r = consumer.complete(query);
            assertEquals(StatusCode.SETUP_NEEDED, r.getStatus());
            assertEquals(setupUrl, ((SetupNeededResponse)r).getSetupUrl());
        }
    }

    public static class CheckAuthTriggeredTest extends IdResBase
    {
        public CheckAuthTriggeredTest(String testName)
        {
            super(testName);
        }

        public void testCheckAuthTriggered()
        {
            Map query = new HashMap();
            query.put("openid.mode", "id_res");
            query.put("openid.return_to", returnTo);
            query.put("openid.identity", serverId);
            query.put("openid.assoc_handle", "notFound");
            query.put("openid.sig", "whatever");
            query.put("openid.signed", "mode");
            query.put(Consumer.getNonceName(), nonce);

            try
            {
                Response r = consumer.complete(query);
                fail(r.getStatus().toString());
            }
            catch (CheckAuthHappened e)
            {
                // this is the expected case
            }
        }

        public void testCheckAuthTriggeredWithAssoc()
        {
            Association assoc = new Association("handle", new byte[20], 1000,
                    "HMAC-SHA1");

            store.storeAssociation(serverUrl, assoc);

            Map query = new HashMap();
            query.put("openid.mode", "id_res");
            query.put("openid.return_to", returnTo);
            query.put("openid.identity", serverId);
            query.put("openid.assoc_handle", "notFound");
            query.put("openid.sig", "whatever");
            query.put("openid.signed", "mode");
            query.put(Consumer.getNonceName(), nonce);

            try
            {
                Response r = consumer.complete(query);
                fail(r.getStatus().toString());
            }
            catch (CheckAuthHappened e)
            {
                // this is the expected case
            }
        }

        public void testExpiredAssoc()
        {
            long earlier = Util.getTimeStamp() - 10;
            String handle = "handle";

            Association assoc = new Association(handle, new byte[20], earlier,
                    1, "HMAC-SHA1");

            store.storeAssociation(serverUrl, assoc);

            Map query = new HashMap();
            query.put("openid.mode", "id_res");
            query.put("openid.return_to", returnTo);
            query.put("openid.identity", serverId);
            query.put("openid.assoc_handle", handle);
            query.put("openid.sig", "whatever");
            query.put("openid.signed", "mode");
            query.put(Consumer.getNonceName(), nonce);

            try
            {
                Response r = consumer.complete(query);
                fail(r.getStatus().toString());
            }
            catch (CheckAuthHappened e)
            {
                // this is the expected case
            }
        }

        public void testNewerAssoc()
        {
            long earlier = Util.getTimeStamp() - 10;
            String goodHandle = "good handle";

            Association goodAssoc = new Association(goodHandle, new byte[20],
                    earlier, 1000, "HMAC-SHA1");

            store.storeAssociation(serverUrl, goodAssoc);

            String badHandle = "bad_handle";

            Association badAssoc = new Association(badHandle, new byte[20],
                    earlier + 5, 1000, "HMAC-SHA1");

            store.storeAssociation(serverUrl, badAssoc);

            store.storeNonce(nonce);

            Map query = new HashMap();
            query.put("openid.mode", "id_res");
            query.put("openid.return_to", returnTo);
            query.put("openid.identity", serverId);
            query.put("openid.assoc_handle", goodHandle);
            query.put(Consumer.getNonceName(), nonce);

            goodAssoc.signMap(Arrays.asList(new String[] {"mode", "return_to",
                    "identity"}), query);

            Response r = consumer.complete(query);
            assertEquals(StatusCode.SUCCESS, r.getStatus());
            assertEquals(consumerId, ((SuccessResponse)r).getIdentityUrl());
        }

    }
}
