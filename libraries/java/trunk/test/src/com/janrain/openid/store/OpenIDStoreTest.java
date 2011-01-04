/*
 * OpenIDStoreTest.java JUnit based test Created on February 27, 2006, 1:01 PM
 */

package com.janrain.openid.store;

import java.util.Arrays;

import junit.framework.TestCase;

import com.janrain.openid.Association;
import com.janrain.openid.Util;

/**
 * @author JanRain, Inc.
 */
public abstract class OpenIDStoreTest extends TestCase
{
    public OpenIDStoreTest(String testName)
    {
        super(testName);
    }

    public OpenIDStore store;

    private long now = Util.getTimeStamp();

    private String serverUrl = "http://www.myopenid.com/openid";

    private Association genAssociation(long issued, long lifetime)
    {
        byte [] secret = Util.randomBytes(20);
        String handle = Util
                .randomString(
                        128,
                        ("ABCDEFGHIJLKMONPQRSTUVWXYZab"
                                + "cdefghijklmnopqrstuvwxyz0123456789`~!@#$%^&*()_+-=[]{}|\\;:'"
                                + "\",./<>?").toCharArray());

        return new Association(handle, secret, now + issued, lifetime,
                "HMAC-SHA1");
    }

    private void checkRetrieve(String url, String handle, Association expected)
    {
        Association retreived = store.getAssociation(url, handle);
        if (expected == null || store.isDumb())
        {
            assertNull(retreived);
        }
        else
        {
            assertEquals(expected, retreived);
        }
    }

    private void checkRemove(String url, String handle, boolean expected)
    {
        boolean present = store.removeAssociation(url, handle);
        boolean expectedPresent = !store.isDumb() && expected;
        assertEquals(present, expectedPresent);
    }

    public void testAssociations()
    {
        Association assoc = genAssociation(0, 600);

        // Make sure that a missing assoociation returns no result
        checkRetrieve(serverUrl, null, null);

        // Check that after storage, gettting returns the same result
        store.storeAssociation(serverUrl, assoc);
        checkRetrieve(serverUrl, null, assoc);

        // more than once
        checkRetrieve(serverUrl, null, assoc);

        // Storing more than once has no ill effect
        store.storeAssociation(serverUrl, assoc);
        checkRetrieve(serverUrl, null, assoc);

        // Removing an association that does not exist returns "not present"
        checkRemove(serverUrl + "x", assoc.getHandle(), false);

        // Removing an association that does not exist returns "not present"
        checkRemove(serverUrl, assoc.getHandle() + "x", false);

        // Removing an association that is present returns "present"
        checkRemove(serverUrl, assoc.getHandle(), true);

        // but not present on subsequent calls
        checkRemove(serverUrl, assoc.getHandle(), false);

        // Put assoc back in the store
        store.storeAssociation(serverUrl, assoc);

        // More recent and expires after assoc
        Association assoc2 = genAssociation(1, 600);
        store.storeAssociation(serverUrl, assoc2);

        // After storing an association with a different handle, but the
        // same server_url, the handle with the later issue date is returned.
        checkRetrieve(serverUrl, null, assoc2);

        // We can still retrieve the older association
        checkRetrieve(serverUrl, assoc.getHandle(), assoc);

        // Plus we can retrieve the association with the later issue date
        // explicitly
        checkRetrieve(serverUrl, assoc2.getHandle(), assoc2);

        // More recent, and expires earlier than assoc2 or assoc. Make sure
        // that we're picking the one with the latest issued date and not
        // taking into account the expiration.
        Association assoc3 = genAssociation(2, 100);
        store.storeAssociation(serverUrl, assoc3);

        checkRetrieve(serverUrl, null, assoc3);
        checkRetrieve(serverUrl, assoc.getHandle(), assoc);
        checkRetrieve(serverUrl, assoc2.getHandle(), assoc2);
        checkRetrieve(serverUrl, assoc3.getHandle(), assoc3);

        checkRemove(serverUrl, assoc2.getHandle(), true);

        checkRetrieve(serverUrl, null, assoc3);
        checkRetrieve(serverUrl, assoc.getHandle(), assoc);
        checkRetrieve(serverUrl, assoc2.getHandle(), null);
        checkRetrieve(serverUrl, assoc3.getHandle(), assoc3);

        checkRemove(serverUrl, assoc2.getHandle(), false);
        checkRemove(serverUrl, assoc3.getHandle(), true);

        checkRetrieve(serverUrl, null, assoc);
        checkRetrieve(serverUrl, assoc.getHandle(), assoc);
        checkRetrieve(serverUrl, assoc2.getHandle(), null);
        checkRetrieve(serverUrl, assoc3.getHandle(), null);

        checkRemove(serverUrl, assoc2.getHandle(), false);
        checkRemove(serverUrl, assoc.getHandle(), true);
        checkRemove(serverUrl, assoc3.getHandle(), false);

        checkRetrieve(serverUrl, null, null);
        checkRetrieve(serverUrl, assoc.getHandle(), null);
        checkRetrieve(serverUrl, assoc2.getHandle(), null);
        checkRetrieve(serverUrl, assoc3.getHandle(), null);

        checkRemove(serverUrl, assoc2.getHandle(), false);
        checkRemove(serverUrl, assoc.getHandle(), false);
        checkRemove(serverUrl, assoc3.getHandle(), false);
    }

    private void checkUseNonce(String nonce, boolean expected)
    {
        boolean actual = store.useNonce(nonce);
        boolean exp = store.isDumb() || expected;
        assertEquals(exp, actual);
    }

    private String genNonce()
    {
        return Util.randomString(8, "abcdefghijklmnopqrstuvwxyz".toCharArray());
    }

    public void testNonces()
    {
        // Random nonce (not in store)
        String nonce = genNonce();

        // A nonce is not present by default
        checkUseNonce(nonce, false);

        // Storing once causes useNonce to return True the first, and only
        // the first, time it is called after the store.
        store.storeNonce(nonce);
        checkUseNonce(nonce, true);
        checkUseNonce(nonce, false);

        // Storing twice has the same effect as storing once
        store.storeNonce(nonce);
        store.storeNonce(nonce);
        checkUseNonce(nonce, true);
        checkUseNonce(nonce, false);
    }

    public void testAuthKey()
    {
        byte [] key = store.getAuthKey();
        byte [] key2 = store.getAuthKey();

        assertTrue(Arrays.equals(key, key2));
    }
}
