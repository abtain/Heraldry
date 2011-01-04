/*
 * UtilTest.java JUnit based test Created on December 8, 2005, 5:12 PM
 */

package com.janrain.openid;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigInteger;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * @author JanRain, Inc.
 */
public class UtilTest extends TestCase
{

    public UtilTest(String testName)
    {
        super(testName);
    }

    protected void setUp() throws Exception
    {
    }

    protected void tearDown() throws Exception
    {
    }

    public static Test suite()
    {
        TestSuite suite = new TestSuite(UtilTest.class);

        return suite;
    }

    /**
     * Test of numberToBase64 method, of class com.janrain.openid.Util.
     */
    public void testNumberToBase64()
    {
        System.out.println("testNumberToBase64");

        InputStream is = null;
        try
        {
            is = getClass().getResourceAsStream("n2b64");
            if (is == null)
            {
                fail("Unable to load test data");
            }

            InputStreamReader ir = new InputStreamReader(is, "US-ASCII");
            BufferedReader br = new BufferedReader(ir);

            while (true)
            {
                String testCase = br.readLine();
                if (testCase == null)
                {
                    break;
                }

                String [] parts = testCase.split("\\s", 2);
                BigInteger input = new BigInteger(parts[1]);
                assertEquals(parts[0], Util.numberToBase64(input));
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

    /**
     * Test of base64ToNumber method, of class com.janrain.openid.Util.
     */
    public void testBase64ToNumber()
    {
        System.out.println("testBase64ToNumber");

        InputStream is = null;
        try
        {
            is = getClass().getResourceAsStream("n2b64");
            if (is == null)
            {
                fail("Unable to load test data");
            }

            InputStreamReader ir = new InputStreamReader(is, "US-ASCII");
            BufferedReader br = new BufferedReader(ir);

            while (true)
            {
                String testCase = br.readLine();
                if (testCase == null)
                {
                    break;
                }

                String [] parts = testCase.split("\\s", 2);
                BigInteger expected = new BigInteger(parts[1]);
                assertEquals(expected, Util.base64ToNumber(parts[0]));
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

    public void testNormalizeUrl()
    {
        System.out.println("testNormalizeUrl");

        assertEquals("http://foo.com/", Util.normalizeUrl("foo.com"));

        assertEquals("http://foo.com/", Util.normalizeUrl("http://foo.com"));
        assertEquals("https://foo.com/", Util.normalizeUrl("https://foo.com"));
        assertEquals("http://foo.com/bar", Util.normalizeUrl("foo.com/bar"));
        assertEquals("http://foo.com/bar", Util
                .normalizeUrl("http://foo.com/bar"));

        assertEquals("http://foo.com/", Util.normalizeUrl("http://foo.com/"));
        assertEquals("https://foo.com/", Util.normalizeUrl("https://foo.com/"));
        assertEquals("https://foo.com/bar", Util
                .normalizeUrl("https://foo.com/bar"));

        assertEquals("http://foo.com/%E8%8D%89", Util
                .normalizeUrl("foo.com/\u8349"));
        assertEquals("http://foo.com/%E8%8D%89", Util
                .normalizeUrl("http://foo.com/\u8349"));

        assertEquals("http://xn--vl1a.com/", Util.normalizeUrl("\u8349.com"));
        assertEquals("http://xn--vl1a.com/", Util
                .normalizeUrl("http://\u8349.com"));
        assertEquals("http://xn--vl1a.com/", Util.normalizeUrl("\u8349.com/"));
        assertEquals("http://xn--vl1a.com/", Util
                .normalizeUrl("http://\u8349.com/"));

        assertEquals("http://xn--vl1a.com/%E8%8D%89", Util
                .normalizeUrl("\u8349.com/\u8349"));
        assertEquals("http://xn--vl1a.com/%E8%8D%89", Util
                .normalizeUrl("http://\u8349.com/\u8349"));

        assertNull(Util.normalizeUrl(null));
        assertNull(Util.normalizeUrl(""));
        assertNull(Util.normalizeUrl("http://"));
    }

}
