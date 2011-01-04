/*
 * Association.java Created on February 7, 2006, 12:58 PM
 */

package com.janrain.openid;

import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * This class represents an association between a server and a consumer. In
 * general, users of this library will never see instances of this object. The
 * only exception is if you implement a custom <code>OpenIDStore</code>.
 * 
 * @author JanRain, Inc.
 */
public class Association implements Serializable
{
    static final long serialVersionUID = -455325682197542781L;

    private String handle;
    private byte [] secret;
    private long issued;
    private long lifetime;
    private String assocType;

    /**
     * Create a new Association instance
     * 
     * @param handle
     *            the association handle
     * @param secret
     *            the shared secret for this association
     * @param issued
     *            the time the secret was issued, in seconds from the epoch
     *            (unix time)
     * @param lifetime
     *            the length of time this association is valid for, in seconds
     *            since the association was issued
     * @param assocType
     *            the type of association this instance represents. The only
     *            valid value for this in OpenID is "HMAC-SHA1" at the moment,
     *            but more types may be added in the future.
     */
    public Association(String handle, byte [] secret, long issued,
                       long lifetime, String assocType)
    {
        this.handle = handle;
        this.secret = secret;
        this.issued = issued;
        this.lifetime = lifetime;
        this.assocType = assocType;
    }

    /**
     * Create a new association instance, setting its issued timestamp to the
     * current time.
     * 
     * @param handle
     *            the association handle
     * @param secret
     *            the shared secret for this association
     * @param lifetime
     *            the length of time this association is valid for, in seconds
     *            since the association was issued
     * @param assocType
     *            the type of association this instance represents. The only
     *            valid value for this in OpenID is "HMAC-SHA1" at the moment,
     *            but more types may be added in the future.
     */
    public Association(String handle, byte [] secret, long lifetime,
                       String assocType)
    {
        this(handle, secret, Util.getTimeStamp(), lifetime, assocType);
    }

    /**
     * This method returns the number of seconds for which this association will
     * still be valid. If the association is no longer valid, this method
     * returns <code>0</code>.
     * 
     * @return the length of time this association will remain valid, in seconds
     */
    public long getRemainingLife()
    {
        return Math.max(0, issued + lifetime - Util.getTimeStamp());
    }

    /**
     * @return the handle for this association
     */
    public String getHandle()
    {
        return handle;
    }

    /**
     * @return the secret for this association
     */
    public byte [] getSecret()
    {
        return secret;
    }

    /**
     * @return the time this secret was issued, in seconds since the epoch (unix
     *         time)
     */
    public long getIssued()
    {
        return issued;
    }

    /**
     * @return the number of seconds this association is valid for, since the
     *         association was issued
     */
    public long getLifeTime()
    {
        return lifetime;
    }

    /**
     * @return the type of this association
     */
    public String getAssocType()
    {
        return assocType;
    }

    /**
     * Compares two associations for equality. They are considered equal if they
     * are the same in all fields.
     */
    public boolean equals(Object o)
    {
        if (!(o instanceof Association))
        {
            return false;
        }
        Association a = (Association)o;

        return a.assocType == assocType && a.handle == handle
                && a.issued == issued && a.lifetime == lifetime
                && Arrays.equals(a.secret, secret);
    }

    /**
     * This method generates a signature for an ordered list of key-value pairs
     * using the secret in this association
     * 
     * @param fields
     *            the ordered list of keys in the Map to sign
     * @param data
     *            a Map containing the key-value pairs to be signed
     * @return the base64-encoded signature
     */
    public String sign(List fields, Map data)
    {
        Map kvData = new HashMap();

        Iterator it = fields.iterator();
        while (it.hasNext())
        {
            String k = (String)it.next();
            String v = (String)data.get("openid." + k);
            kvData.put(k, v);
        }

        String kvForm = Util.toKVForm(fields, kvData);
        byte [] sig;
        try
        {
            sig = Util.hmacSha1(secret, kvForm.getBytes("UTF-8"));
        }
        catch (UnsupportedEncodingException e)
        {
            // can't happen
            return null;
        }

        return Util.toBase64(sig);
    }

    /**
     * This method generates a signature for an ordered list of key-value pairs
     * using the secret in this association. It writes the generated signature
     * values into the Map that was passed in,
     * 
     * @param fields
     *            the ordered list of keys in the Map to sign
     * @param data
     *            a Map containing the key-value pairs to be signed
     */
    public void signMap(List fields, Map data)
    {
        String sig = sign(fields, data);
        StringBuffer signedBuffer = new StringBuffer();
        Iterator it = fields.iterator();
        while (it.hasNext())
        {
            signedBuffer.append(it.next());
            signedBuffer.append(',');
        }
        signedBuffer.deleteCharAt(signedBuffer.length() - 1);

        String signed = signedBuffer.toString();
        data.put("openid.sig", sig);
        data.put("openid.signed", signed);
    }
}
