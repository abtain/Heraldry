/*
 * MemoryStoreTest.java JUnit based test Created on February 22, 2006, 10:30 AM
 */

package com.janrain.openid.store;

import junit.framework.Test;
import junit.framework.TestSuite;

/**
 * @author JanRain, Inc.
 */
public class MemoryStoreTest extends OpenIDStoreTest
{
    public MemoryStoreTest(String testName)
    {
        super(testName);
    }

    protected void setUp() throws Exception
    {
        store = new MemoryStore();
    }

    protected void tearDown() throws Exception
    {
        // do nothing
    }

    public static Test suite()
    {
        TestSuite suite = new TestSuite(MemoryStoreTest.class);

        return suite;
    }
}
