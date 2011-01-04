package com.janrain.openid.consumer;

import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import com.janrain.openid.Util;
import com.janrain.openid.store.OpenIDStore;

/**
 * <p>
 * This class is the main interface with the OpenID consumer library. The only
 * part of the library which has to be used and isn't documented in full here is
 * the store required to create an <code>Consumer</code> instance. See the
 * constructor for more information on stores, see the
 * <code>com.janrain.openid.store</code> package.
 * </p>
 * <h1>OVERVIEW</h1>
 * <p>
 * The OpenID identity verification process most commonly uses the following
 * steps, as visible to the user of this library:
 * </p>
 * <ol>
 * <li>The user enters their OpenID into a field on the consumer's site, and
 * hits a login button.</li>
 * <li>The consumer site discovers the user's OpenID server using the YADIS
 * protocol.</li>
 * <li>The consumer site sends the browser a redirect to the identity server.
 * This is the authentication request as described in the OpenID specification.</li>
 * <li> The identity server's site sends the browser a redirect back to the
 * consumer site. This redirect contains the server's response to the
 * authentication request.</li>
 * </ol>
 * <p>
 * The most important part of the flow to note is the consumer's site must
 * handle two separate HTTP requests in order to perform the full identity
 * check.
 * </p>
 * <h1>LIBRARY DESIGN</h1>
 * <p>
 * This consumer library is designed with that flow in mind. The goal is to make
 * it as easy as possible to perform the above steps securely.
 * </p>
 * <p>
 * At a high level, there are two important parts in the consumer library. The
 * first important part is this class, which contains the interface to actually
 * use this library. The second is the
 * <code>com.janrain.openid.store.OpenIDStore</code> class, which describes
 * the interface to use if you need to create a custom method for storing the
 * state this library needs to maintain between requests.
 * </p>
 * <h1>STORES AND DUMB MODE</h1>
 * <p>
 * OpenID is a protocol that works best when the consumer site is able to store
 * some state. This is the normal mode of operation for the protocol, and is
 * sometimes referred to as smart mode. There is also a fallback mode, known as
 * dumb mode, which is available when the consumer site is not able to store
 * state. This mode should be avoided when possible, as it leaves the
 * implementation more vulnerable to replay attacks.
 * </p>
 * <p>
 * The mode the library works in for normal operation is determined by the store
 * that it is given. The store is an abstraction that handles the data that the
 * consumer needs to manage between http requests in order to operate
 * efficiently and securely.
 * </p>
 * <p>
 * One store implementation is provided, and the interface is fully documented
 * so that custom stores can be used as well. See the documentation for the
 * <code>com.janrain.openid.store.OpenIDStore</code> class for more
 * information on the interface for stores. The provided store is a thread-safe
 * in-memory store that can be serialized on application shutdown. As such, it's
 * ideal for single-JVM servers. Servers that are distributed over multiple JVMs
 * will need custom store implementations.
 * </p>
 * <p>
 * There is an additional concrete store provided that puts the system in dumb
 * mode. This is not recommended, as it removes the library's ability to stop
 * replay attacks reliably. It still uses time-based checking to make replay
 * attacks only possible within a small window, but they remain possible within
 * that window. This store should only be used if the consumer site has no way
 * to retain data between requests at all.
 * </p>
 * <h1>IMMEDIATE MODE </h1>
 * <p>
 * In the flow described above, the user may need to confirm to the identity
 * server that it's ok to authorize his or her identity. The server may draw
 * pages asking for information from the user before it redirects the browser
 * back to the consumer's site. This is generally transparent to the consumer
 * site, so it is typically ignored as an implementation detail.
 * </p>
 * <p>
 * There can be times, however, where the consumer site wants to get a response
 * immediately. When this is the case, the consumer can put the library in
 * immediate mode. In immediate mode, there is an extra response possible from
 * the server, which is essentially the server reporting that it doesn't have
 * enough information to answer the question yet. In addition to saying that,
 * the identity server provides a URL to which the user can be sent to provide
 * the needed information and let the server finish handling the original
 * request.
 * </p>
 * <h1>USING THIS LIBRARY</h1>
 * <p>
 * Integrating this library into an application is usually a relatively
 * straightforward process. The process should basically follow this plan:
 * </p>
 * <p>
 * Add an OpenID login field somewhere on your site. When an OpenID is entered
 * in that field and the form is submitted, it should make a request to the your
 * site which includes that OpenID URL.
 * </p>
 * <p>
 * First, the application should instantiate the <code>Consumer</code> class
 * using the store of choice. In addition to a store, the constructor also takes
 * a <code>Map</code> to use as per-user state storage. This <code>Map</code>
 * should be stored in the user session, and is referred to as the session
 * <code>Map</code>.
 * </p>
 * <p>
 * Next, the application should call the <code>begin</code> method on the
 * <code>Consumer</code> instance. This method takes the OpenID URL. The
 * <code>begin</code> method returns an <code>AuthRequest</code> object.
 * </p>
 * <p>
 * Next, the application should call the <code>redirectURL</code> method on
 * the <code>AuthRequest</code> object. The parameter <code>returnTo</code>
 * is the URL that the OpenID server will send the user back to after attempting
 * to verify his or her identity. The <code>trustRoot</code> parameter is the
 * URL (or URL pattern) that identifies your web site to the user when he or she
 * is authorizing it. Send a redirect to the resulting URL to the user's
 * browser.
 * </p>
 * <p>
 * That's the first half of the authentication process. The second half of the
 * process is done after the user's ID server sends the user's browser a
 * redirect back to your site to complete their login.
 * </p>
 * <p>
 * When that happens, the user will contact your site at the URL given as the
 * <code>returnTo</code> URL to the <code>redirectURL</code> call made
 * above. The request will have several query parameters added to the URL by the
 * identity server as the information necessary to finish the request.
 * </p>
 * <p>
 * Get an <code>Consumer</code> instance, and call its <code>complete</code>
 * method, passing in all the received query arguments. There are multiple
 * possible return types possible from that method. These indicate the whether
 * or not the login was successful, and include any additional information
 * appropriate for their type.
 * </p>
 * 
 * @author JanRain, Inc.
 */
public class Consumer
{
    private static String sessionKeyPrefix = "_openid_consumer_";
    private static String tokenName = "last_token";
    private static String managerName = "manager";

    private Map session;
    private OpenIDStore store;
    private GenericConsumer consumer;

    /**
     * Creates a new Consumer instance.
     * 
     * @param session
     *            a <code>Map</code> that the application will preserve
     *            between the current user's requests
     * @param store
     *            the store that will be used to keep this site's state
     */
    public Consumer(Map session, OpenIDStore store)
    {
        this.session = session;
        this.store = store;
        consumer = new GenericConsumer(this.store);
    }

    /**
     * This method starts the OpenID authentication process.
     * 
     * @param userUrl
     *            The identity string provided by the user. This method performs
     *            transformations as defined by the OpenID specification on the
     *            input value to normalize it. For instance, the value
     *            <code>"example.com"</code> will converted to
     *            <code>"http://example.com/"</code>, and then any redirects
     *            the server may issue.
     * @return An <code>AuthRequest</code> object containing information about
     *         the OpenID request that is about to be made.
     * @throws IOException
     *             when the entered value isn't a fetchable URL, when the URL
     *             doesn't support OpenID, or when all OpenID services for a
     *             given URL have failed to work
     */
    public AuthRequest begin(String userUrl) throws IOException
    {
        String openidUrl = Util.normalizeUrl(userUrl);
        DiscoveryManager dm = (DiscoveryManager)session.get(sessionKeyPrefix
                + managerName);

        if (dm == null)
        {
            dm = new DiscoveryManager(openidUrl);
            session.put(sessionKeyPrefix + managerName, dm);
        }

        if (dm.isEmpty())
        {
            session.remove(sessionKeyPrefix + managerName);
            throw new IOException("No OpenID services found at that URL");
        }

        if (!dm.hasNext())
        {
            session.remove(sessionKeyPrefix + managerName);
            throw new IOException(
                    "No usable OpenID services found for that URL");
        }

        return beginWithoutDiscovery(dm.getNext());
    }

    /**
     * This method starts OpenID authentication without doing OpenID server
     * discovery. This method is called by <code>begin</code> to do its
     * post-discovery work. It is publicly visible for use when consumers want
     * to do their own OpenID service discovery.
     * 
     * @param service
     *            the service information needed by the library
     * @return An <code>AuthRequest</code> object containing information about
     *         the OpenID request that is about to be made.
     */
    public AuthRequest beginWithoutDiscovery(OpenIDService service)
    {
        AuthRequest result = consumer.begin(service);
        session.put(sessionKeyPrefix + tokenName, result.getToken());
        return result;
    }

    /**
     * This method interpret's a server's response to an OpenID request.
     * 
     * @param query
     *            a <code>Map</code> from query parameter name to query
     *            parameter value, <code>String</code> to <code>String</code>.
     *            As many applications using this library will be servlets, a
     *            convenience function has been provided to convert between the
     *            format <code>getParameterMap</code> provides and the format
     *            this method expects. See <code>filterArgs</code>.
     * @return a <code>Response</code> subclass containing the status of the
     *         authentication request
     */
    public Response complete(Map query)
    {
        Token token = (Token)session.get(sessionKeyPrefix + tokenName);

        Response result;
        if (token == null)
        {
            result = new FailureResponse(null, "No session state found");
        }
        else
        {
            result = consumer.complete(query, token);
            session.remove(sessionKeyPrefix + tokenName);
        }

        StatusCode status = result.getStatus();

        String identityUrl = null;
        if (status == StatusCode.SUCCESS)
        {
            SuccessResponse sr = (SuccessResponse)result;
            identityUrl = sr.getIdentityUrl();
        }
        else if (status == StatusCode.CANCELLED)
        {
            CancelResponse cr = (CancelResponse)result;
            identityUrl = cr.getIdentityUrl();
        }

        if (identityUrl != null)
        {
            session.remove(sessionKeyPrefix + managerName);
        }

        return result;
    }

    /**
     * @param args
     *            a <code>Map</code> with <code>String</code>s as keys and
     *            <code>String []</code>s as values, like the
     *            <code>Map</code>s returned in the servlet API.
     * @return a <code>Map</code> with <code>String</code>s as keys and
     *         <code>String</code>s as values, suitable for use in the
     *         <code>complete</code> method.
     */
    public static Map filterArgs(Map args)
    {
        Map result = new HashMap();
        Iterator it = args.entrySet().iterator();
        while (it.hasNext())
        {
            Map.Entry e = (Map.Entry)it.next();
            String k = (String)e.getKey();
            String [] v = (String [])e.getValue();
            result.put(k, v[0]);
        }
        return result;
    }

    /**
     * @return a list of characters that will be used for nonces
     */
    public static char [] getNonceChars()
    {
        return GenericConsumer.getNonceChars();
    }

    /**
     * @param nonceChars
     *            the new list of nonce characters
     */
    public static void setNonceChars(char [] nonceChars)
    {
        GenericConsumer.setNonceChars(nonceChars);
    }

    /**
     * @return the length of nonces
     */
    public static int getNonceLen()
    {
        return GenericConsumer.getNonceLen();
    }

    /**
     * @param nonceLen
     *            the new length of nonces
     */
    public static void setNonceLen(int nonceLen)
    {
        GenericConsumer.setNonceLen(nonceLen);
    }

    /**
     * @return the number of seconds an authentication requst is valid for
     */
    public static long getTokenLifetime()
    {
        return GenericConsumer.getTokenLifetime();
    }

    /**
     * @param tokenLifetime
     *            the new number of seconds an authentication request is valid
     *            for
     */
    public static void setTokenLifetime(long tokenLifetime)
    {
        GenericConsumer.setTokenLifetime(tokenLifetime);
    }

    /**
     * @return the name of the URL parameter that will be used to store the
     *         nonce
     */
    public static String getNonceName()
    {
        return GenericConsumer.getNonceName();
    }

    /**
     * @param nonceName
     *            the new name of the URL parameter that will be used to store
     *            the nonce.
     */
    public static void setNonceName(String nonceName)
    {
        GenericConsumer.setNonceName(nonceName);
    }
}
