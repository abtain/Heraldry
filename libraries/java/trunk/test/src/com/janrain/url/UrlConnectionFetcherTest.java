/*
 * UrlConnectionFetcherTest.java JUnit based test Created on December 15, 2005,
 * 1:55 PM
 */

package com.janrain.url;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * @author JanRain, Inc.
 */
public class UrlConnectionFetcherTest extends TestCase
{
    private static InetAddress host;

    private static int port = 9111;

    private static String base;

    static
    {
        try
        {
            host = InetAddress.getByName("localhost");
        }
        catch (UnknownHostException e)
        {
            // I suppose this could possibly happen on a windows machine
            // without TCP/IP installed.
        }

        base = "http://localhost:" + port;
        Logger.getLogger("com.janrain.openid").setLevel(Level.SEVERE);
    }

    public UrlConnectionFetcherTest(String testName)
    {
        super(testName);
    }

    HTTPFetcher oidFetch;

    Thread t;

    protected void setUp() throws Exception
    {
        oidFetch = HTTPFetcher.getFetcher();
        t = new Thread(new FakeHTTPServer());
        t.setDaemon(true);
        t.start();
        synchronized (this)
        {
            try
            {
                this.wait();
            }
            catch (InterruptedException e)
            {
                // ignore
            }
        }
    }

    protected void tearDown() throws Exception
    {
    }

    private class FakeHTTPServer implements Runnable
    {
        boolean accepting = true;

        public void run()
        {
            try
            {
                ServerSocket ss = new ServerSocket(port, -1, host);
                synchronized (UrlConnectionFetcherTest.this)
                {
                    UrlConnectionFetcherTest.this.notify();
                }
                while (accepting)
                {
                    accepting = false;
                    Socket s = ss.accept();

                    BufferedReader r = new BufferedReader(
                            new InputStreamReader(s.getInputStream(), "UTF-8"));
                    String request = r.readLine();

                    int contentLength = 0;
                    StringBuffer headers = new StringBuffer();
                    for (String l = r.readLine(); !l.equals(""); l = r
                            .readLine())
                    {
                        if (l.startsWith("Content-Length: "))
                        {
                            contentLength = Integer.parseInt(l.substring(16));
                        }
                        headers.append(l);
                        headers.append("\r\n");
                    }
                    StringBuffer body = new StringBuffer();

                    char [] c = new char[1024];
                    while (contentLength > 0)
                    {
                        int read = r.read(c, 0, Math.min(contentLength,
                                c.length));
                        if (read == -1) break;

                        body.append(c, 0, read);
                        contentLength -= read;
                    }

                    String response = getResponse(request, headers.toString(),
                            body.toString());
                    Writer w = new OutputStreamWriter(s.getOutputStream(),
                            "UTF-8");
                    w.write(response);
                    w.flush();

                    s.close();
                }
                ss.close();
            }
            catch (IOException e)
            {
                // nothing really can be done, other than yelling about it.
                e.printStackTrace();
            }
        }

        private String getResponse(String request, String headers, String body)
        {
            String [] parts = request.split(" ");

            String method = parts[0];
            String path = parts[1];

            if (path.equals("/closed"))
            {
                return "";
            }

            // all other requests should be for /number
            StringBuffer result = new StringBuffer("HTTP/1.1 ");

            result.append(path.substring(1));
            result.append(" CALLOO CALLAY\r\n");

            if (method.equals("GET"))
            {
                if (path.charAt(1) == '3')
                {
                    result.append("Location: ");
                    result.append(base);
                    result.append("/200\r\n");
                    accepting = true;
                }

                result
                        .append("Content-Type: text/plain; charset=utf-8\r\n\r\n");

                result.append("This is the world's most boring content.\r\n");

            }
            else if (method.equals("POST"))
            {
                result.append("Content-Type: text/plain\r\n\r\n");

                result.append("This is what you posted:\r\n");
                result.append(body);
            }
            return result.toString();
        }
    }

    public static Test suite()
    {
        TestSuite suite = new TestSuite(UrlConnectionFetcherTest.class);

        return suite;
    }

    public void testGet200()
    {
        System.out.println("testGet200");
        FetchResponse f = oidFetch.fetch(base + "/200");
        assertEquals("text/plain; charset=utf-8", ((List)f.getHeaders().get(
                "Content-Type")).get(0));
        assertEquals(200, f.getStatusCode());
        assertEquals(base + "/200", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet301()
    {
        System.out.println("testGet301");
        FetchResponse f = oidFetch.fetch(base + "/301");
        assertEquals(200, f.getStatusCode());
        assertEquals(base + "/200", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet302()
    {
        System.out.println("testGet302");
        FetchResponse f = oidFetch.fetch(base + "/302");
        assertEquals(200, f.getStatusCode());
        assertEquals(base + "/200", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet303()
    {
        System.out.println("testGet303");
        FetchResponse f = oidFetch.fetch(base + "/303");
        assertEquals(200, f.getStatusCode());
        assertEquals(base + "/200", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet307()
    {
        System.out.println("testGet307");
        FetchResponse f = oidFetch.fetch(base + "/307");
        assertEquals(200, f.getStatusCode());
        assertEquals(base + "/200", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet400()
    {
        System.out.println("testGet400");
        FetchResponse f = oidFetch.fetch(base + "/400");
        assertEquals(400, f.getStatusCode());
        assertEquals(base + "/400", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet403()
    {
        System.out.println("testGet403");
        FetchResponse f = oidFetch.fetch(base + "/403");
        assertEquals(403, f.getStatusCode());
        assertEquals(base + "/403", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet404()
    {
        System.out.println("testGet404");
        FetchResponse f = oidFetch.fetch(base + "/404");
        assertEquals(404, f.getStatusCode());
        assertEquals(base + "/404", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet500()
    {
        System.out.println("testGet500");
        FetchResponse f = oidFetch.fetch(base + "/500");
        assertEquals(500, f.getStatusCode());
        assertEquals(base + "/500", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGet503()
    {
        System.out.println("testGet503");
        FetchResponse f = oidFetch.fetch(base + "/503");
        assertEquals(503, f.getStatusCode());
        assertEquals(base + "/503", f.getFinalUrl());
        assertEquals("This is the world's most boring content.\r\n", f
                .getContent());
    }

    public void testGetInvalid()
    {
        System.out.println("testGetInvalid");
        assertNull(oidFetch.fetch(base + "/closed"));
        assertNull(oidFetch.fetch("http://invalid.janrain.com"));
        assertNull(oidFetch.fetch("not:a/url"));
        assertNull(oidFetch.fetch("ftp://janrain.com/pub/"));
    }

    public void testPost200()
    {
        System.out.println("testPost200");
        FetchResponse f = oidFetch.fetch(base + "/200", "one fish, two fish");
        assertEquals(200, f.getStatusCode());
        assertEquals(base + "/200", f.getFinalUrl());
        assertEquals("This is what you posted:\r\none fish, two fish", f
                .getContent());
    }

    public void testPost400()
    {
        System.out.println("testPost400");
        FetchResponse f = oidFetch.fetch(base + "/400", "red fish, blue fish");
        assertEquals(400, f.getStatusCode());
        assertEquals(base + "/400", f.getFinalUrl());
        assertEquals("This is what you posted:\r\nred fish, blue fish", f
                .getContent());
    }

    public void testPost403()
    {
        System.out.println("testPost403");
        FetchResponse f = oidFetch.fetch(base + "/403", "bob");
        assertEquals(403, f.getStatusCode());
        assertEquals(base + "/403", f.getFinalUrl());
        assertEquals("This is what you posted:\r\nbob", f.getContent());
    }

    public void testPost404()
    {
        System.out.println("testPost404");
        FetchResponse f = oidFetch.fetch(base + "/404", "a=b&c=d");
        assertEquals(404, f.getStatusCode());
        assertEquals(base + "/404", f.getFinalUrl());
        assertEquals("This is what you posted:\r\na=b&c=d", f.getContent());
    }

    public void testPost500()
    {
        System.out.println("testPost500");
        FetchResponse f = oidFetch.fetch(base + "/500", "la brea");
        assertEquals(500, f.getStatusCode());
        assertEquals(base + "/500", f.getFinalUrl());
        assertEquals("This is what you posted:\r\nla brea", f.getContent());
    }

    public void testPost503()
    {
        System.out.println("testPost503");
        FetchResponse f = oidFetch.fetch(base + "/503", "Me!");
        assertEquals(503, f.getStatusCode());
        assertEquals(base + "/503", f.getFinalUrl());
        assertEquals("This is what you posted:\r\nMe!", f.getContent());
    }

    public void testPostInvalid()
    {
        System.out.println("testPostInvalid");
        assertNull(oidFetch.fetch(base + "/closed", ""));
        assertNull(oidFetch.fetch("http://invalid.janrain.com", ""));
        assertNull(oidFetch.fetch("not:a/url", ""));
        assertNull(oidFetch.fetch("ftp://janrain.com/pub/", ""));
    }
}
