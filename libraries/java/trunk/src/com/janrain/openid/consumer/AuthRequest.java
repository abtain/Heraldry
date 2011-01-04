package com.janrain.openid.consumer;

import java.util.HashMap;
import java.util.Map;

import com.janrain.openid.Association;
import com.janrain.openid.Util;

/**
 * This class contains the intermediate status in an OpenID authentication
 * request. The <code>begin</code> method in
 * <code>com.janrain.openid.consumer.Consumer</code> returns an instance of
 * this class. This class supports adding queries to the request before it gets
 * sent for using OpenID extensions. It also gives access to some information
 * about the claimed identity before it is used. The information available
 * through the <code>getService</code> method allows you to determine the
 * identity a user is claiming and the ID Server they are using before
 * proceeding with the OpenID process. This can be used to black/white-list IDs
 * or ID servers, or to use logic based on user-history to decide what, if any,
 * extensions to use.
 * 
 * @author JanRain, Inc.
 */
public class AuthRequest
{
    private Association assoc;
    private Token token;
    private OpenIDService service;

    private Map extraArgs = new HashMap();
    private Map returnToArgs = new HashMap();

    /**
     * Create a new AuthRequest object
     * 
     * @param token
     * @param assoc
     * @param service
     */
    AuthRequest(Token token, Association assoc, OpenIDService service)
    {
        this.token = token;
        this.assoc = assoc;
        this.service = service;
    }

    /**
     * @return the association that will be used in the request this generates
     */
    public Association getAssoc()
    {
        return assoc;
    }

    /**
     * @return the extra query args that will be sent with this request
     */
    public Map getExtraArgs()
    {
        return extraArgs;
    }

    /**
     * @return the extra query args that will be added to the return to URL
     */
    public Map getReturnToArgs()
    {
        return returnToArgs;
    }

    /**
     * @return the information on the identity and server which will be used for
     *         this request
     */
    public OpenIDService getService()
    {
        return service;
    }

    /**
     * @return the token that will be used to store data between this request
     *         and the return request
     */
    public Token getToken()
    {
        return token;
    }

    /**
     * This method adds an extension argument to this request.
     * 
     * @param namespace
     *            the namespace for the extension. For example, the simple
     *            registration extension uses the namespace "sreg"
     * @param key
     *            the key within the extension namespace. For example, the
     *            nickname field in the simple registration extension's key is
     *            "nickname"
     * @param value
     *            the value to provide to the server for this argument
     */
    public void addExtensionArg(String namespace, String key, String value)
    {
        String name = "openid." + namespace + "." + key;
        extraArgs.put(name, value);
    }

    /*
     * Add a key-value pair to the return to args
     */
    void addReturnToArg(String key, String value)
    {
        returnToArgs.put(key, value);
    }

    /**
     * This method returns a URL to redirect the user to in order to continue
     * the authentication process.
     * 
     * @param trustRoot
     *            this is the url the server will ask the user to approve. It
     *            must be a parent url of the return to url
     * @param returnTo
     *            this is the url the server will send its response to. It needs
     *            to handle the server's response
     * @param immediate
     *            <code>true</code> to use immediate mode, <false> for setup
     *            mode
     * @return a URL to direct the user to so the Authentication proceeds
     */
    public String redirectUrl(String trustRoot, String returnTo,
            boolean immediate)
    {
        String mode = "checkid_" + (immediate ? "immediate" : "setup");
        returnTo = Util.appendArgs(returnTo, returnToArgs);

        Map redirArgs = new HashMap();
        redirArgs.put("openid.mode", mode);
        redirArgs.put("openid.identity", service.getDelegate());
        redirArgs.put("openid.return_to", returnTo);
        redirArgs.put("openid.trust_root", trustRoot);

        if (assoc != null)
        {
            redirArgs.put("openid.assoc_handle", assoc.getHandle());
        }

        redirArgs.putAll(extraArgs);
        return Util.appendArgs(service.getServerUrl(), redirArgs);
    }

    /**
     * Equivalent to calling redirectUrl((trustRoot, returnTo, false);
     * 
     * @param trustRoot
     *            this is the url the server will ask the user to approve. It
     *            must be a parent url of the return to url
     * @param returnTo
     *            this is the url the server will send its response to. It needs
     *            to handle the server's response
     * @return a URL to direct the user to so the Authentication proceeds
     */
    public String redirectUrl(String trustRoot, String returnTo)
    {
        return redirectUrl(trustRoot, returnTo, false);
    }
}
