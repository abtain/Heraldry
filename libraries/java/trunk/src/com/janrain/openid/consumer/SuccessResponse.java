package com.janrain.openid.consumer;

import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * A response with a status of <code>StatusCode.Success</code>. This response
 * indicates that the user's authentication request was successful. It's
 * important to use the value returned by <code>getIdentityUrl</code> as the
 * user's proven identifier.
 * 
 * @author JanRain, Inc.
 */
public class SuccessResponse extends Response
{
    private Map signedArgs;

    public static SuccessResponse fromQuery(String identityUrl, Map query,
            String signed)
    {
        String [] signedNames = signed.split(",");
        Map signedArgs = new HashMap();
        for (int i = 0; i < signedNames.length; i++)
        {
            String key = "openid." + signedNames[i];
            Object value = query.get(key);
            if (value == null)
            {
                value = "";
            }
            signedArgs.put(key, value);
        }

        return new SuccessResponse(identityUrl, signedArgs);
    }

    public SuccessResponse(String identityUrl, Map signedArgs)
    {
        super(StatusCode.SUCCESS, identityUrl);
        this.signedArgs = signedArgs;
    }

    /**
     * @return the entire set of arguments signed by the server
     */
    public Map getSignedArgs()
    {
        return Collections.unmodifiableMap(signedArgs);
    }

    /**
     * This method returns a Map of signed extension arguments returned by the
     * server, based on an extension prefix.
     * 
     * @param prefix
     *            the extension prefix to check for
     * @return the signed arguments in that extension namespace
     */
    public Map getExtensionResponse(String prefix)
    {
        Map result = new HashMap();

        prefix = "openid." + prefix + ".";
        int len = prefix.length();

        Iterator it = signedArgs.entrySet().iterator();
        while (it.hasNext())
        {
            Map.Entry e = (Map.Entry)it.next();
            String k = (String)e.getKey();
            if (k.startsWith(prefix))
            {
                String rk = k.substring(len);
                String v = (String)e.getValue();
                result.put(rk, v);
            }
        }

        return Collections.unmodifiableMap(result);
    }

    /**
     * @return the signed <code>openid.return_to</code> argument from this
     *         response, or <code>null</code> if there wasn't a signed
     *         <code>openid.return_to</code> field
     */
    public String getReturnTo()
    {
        return (String)signedArgs.get("openid.return_to");
    }
}
