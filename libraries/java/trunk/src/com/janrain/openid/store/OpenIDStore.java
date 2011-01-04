/*
 * OpenIDStore.java Created on February 3, 2006, 12:39 PM
 */

package com.janrain.openid.store;

import com.janrain.openid.Association;

/**
 * This is the superclass for all store objects the OpenID library uses. It is a
 * single class that provides all of the persistence mechanisms that the OpenID
 * library needs, for both servers and consumers.
 * 
 * @author JanRain, Inc.
 */
public abstract class OpenIDStore
{
    /**
     * The length of the auth key that should be returned by the
     * <code>getAuthKey</code> method.
     */
    public static final int AUTH_KEY_LEN = 20;

    /**
     * This method returns a key used to sign the tokens, to ensure that they
     * haven't been tampered with in transit. It should return the same key
     * every time it is called. The key returned should be
     * <code>AUTH_KEY_LEN<code> bytes long.
     * 
     * @return
     */
    public abstract byte [] getAuthKey();

    /**
     * This method puts a <code>com.janrain.openid.Association</code> object
     * into storage, retrievable by server URL and handle.
     * 
     * @param serverUrl
     *            the URL of the identity server that this association is with.
     *            Because of the way the server portion of the library uses this
     *            interface, don't assume there are any limitations on the
     *            character set of the input string. In particular, expect to
     *            see unescaped non-url-safe characters in the server_url field.
     * @param assoc
     *            the <code>com.janrain.openid.Association</code> to store
     */
    public abstract void storeAssociation(String serverUrl, Association assoc);

    /**
     * <p>
     * This method returns an C{L{Association <openid.association.Association>}}
     * object from storage that matches the server URL and, if specified,
     * handle. It returns C{None} if no such association is found or if the
     * matching association is expired.
     * </p>
     * <p>
     * If no handle is specified, the store may return any association which
     * matches the server URL. If multiple associations are valid, the
     * recommended return value for this method is the one that will remain
     * valid for the longest duration.
     * </p>
     * <p>
     * This method is allowed (and encouraged) to garbage collect expired
     * associations when found. This method must not return expired
     * associations.
     * </p>
     * 
     * @param serverUrl
     *            the URL of the identity server to get the association for.
     *            Because of the way the server portion of the library uses this
     *            interface, don't assume there are any limitations on the
     *            character set of the input string. In particular, expect to
     *            see unescaped non-url-safe characters in the server_url field.
     * @param handle
     *            the handle of the specific association to get, or null to
     *            indicate that any association for the given server will work.
     * @return the <code>com.janrain.openid.Association</code> for the given
     *         serverUrl and handle
     */
    public abstract Association getAssociation(String serverUrl, String handle);

    /**
     * This method is equivalent to calling getAssociation(serverUrl, null);
     * 
     * @param serverUrl
     *            the URL of the identity server to get the association for.
     *            Because of the way the server portion of the library uses this
     *            interface, don't assume there are any limitations on the
     *            character set of the input string. In particular, expect to
     *            see unescaped non-url-safe characters in the server_url field.
     * @return the <code>com.janrain.openid.Association</code> for the given
     *         serverUrl and handle
     */
    public Association getAssociation(String serverUrl)
    {
        return getAssociation(serverUrl, null);
    }

    /**
     * This method removes the matching association if it's found, and returns
     * whether the association was removed or not.
     * 
     * @param serverUrl
     *            The URL of the identity server the association to remove
     *            belongs to. Because of the way the server portion of the
     *            library uses this interface, don't assume there are any
     *            limitations on the character set of the input string. In
     *            particular, expect to see unescaped non-url-safe characters in
     *            the server_url field.
     * @param handle
     *            This is the handle of the association to remove. If there
     *            isn't an association found that matches both the given URL and
     *            handle, then there was no matching handle found.
     * @return Returns whether or not the given association existed.
     */
    public abstract boolean removeAssociation(String serverUrl, String handle);

    /**
     * Stores a nonce. This is used by the consumer to prevent replay attacks.
     * 
     * @param nonce
     *            The nonce to store.
     */
    public abstract void storeNonce(String nonce);

    /**
     * <p>
     * This method is called when the library is attempting to use a nonce. If
     * the nonce is in the store, this method removes it and returns a value
     * which evaluates as true. Otherwise it returns a value which evaluates as
     * false.
     * </p>
     * <p>
     * This method is allowed and encouraged to treat nonces older than some
     * period (a very conservative window would be 6 hours, for example) as no
     * longer existing, and return False and remove them.
     * </p>
     * 
     * @param nonce
     * @return
     */
    public abstract boolean useNonce(String nonce);

    /**
     * <p>
     * This method must return <code>true</code> if the store is a
     * dumb-mode-style store. The default implementation returns
     * <code>False</code>.
     * </p>
     * <p>
     * In general, any custom subclass of <code>OpenIDStore</code> won't
     * override this method, as custom subclasses are only likely to be created
     * when the store is fully functional.
     * </p>
     * 
     * @return <code>true</code> if the store works fully, <code>false</code>
     *         if the consumer will have to use dumb mode to use this store.
     */
    public boolean isDumb()
    {
        return false;
    }
}
