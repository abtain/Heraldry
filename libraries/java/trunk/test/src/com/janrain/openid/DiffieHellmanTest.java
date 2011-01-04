/*
 * DiffieHellmanTest.java JUnit based test Created on December 8, 2005, 4:36 PM
 */

package com.janrain.openid;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigInteger;

import junit.framework.Assert;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * @author JanRain, Inc.
 */
public class DiffieHellmanTest extends TestCase
{

    public DiffieHellmanTest(String testName)
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
        TestSuite suite = new TestSuite(DiffieHellmanTest.class);

        return suite;
    }

    /**
     * Test of getSharedSecret method, of class
     * com.janrain.openid.DiffieHellman.
     */
    public void testGetSharedSecret()
    {
        System.out.println("testGetSharedSecret");

        for (int i = 0; i < 10; i++)
        {
            DiffieHellman dh1 = new DiffieHellman();
            DiffieHellman dh2 = new DiffieHellman();

            BigInteger secret1 = dh1.getSharedSecret(dh2.getPublicKey());
            BigInteger secret2 = dh2.getSharedSecret(dh1.getPublicKey());

            Assert.assertEquals(secret1, secret2);
        }
    }

    /**
     * Test of getPublicKey method, of class com.janrain.openid.DiffieHellman.
     */
    public void testGetPublicKey()
    {
        System.out.println("testGetPublicKey");

        /*
         * No additional testing over that done for setPrivateKey is currently
         * necessary.
         */
    }

    /**
     * Test of setPrivateKey method, of class com.janrain.openid.DiffieHellman.
     */
    public void testSetPrivateKey()
    {
        System.out.println("testSetPrivateKey");

        InputStream is = null;
        try
        {
            is = getClass().getResourceAsStream("dhpriv");
            if (is == null)
            {
                fail("Unable to load test data");
            }

            InputStreamReader ir = new InputStreamReader(is, "US-ASCII");
            BufferedReader br = new BufferedReader(ir);

            DiffieHellman dh = new DiffieHellman();
            while (true)
            {
                String testCase = br.readLine();
                if (testCase == null)
                {
                    break;
                }

                String [] parts = testCase.split("\\s", 2);
                BigInteger input = new BigInteger(parts[0]);
                BigInteger expected = new BigInteger(parts[1]);
                dh.setPrivateKey(input);
                Assert.assertEquals(expected, dh.getPublicKey());
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

}
