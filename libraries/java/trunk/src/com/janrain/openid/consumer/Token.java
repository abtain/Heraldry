/*
 * Token.java Created on January 26, 2006, 10:36 AM
 */

package com.janrain.openid.consumer;

import java.io.Serializable;
import java.io.UnsupportedEncodingException;
import java.util.Arrays;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.janrain.openid.Util;

/**
 * This class contains information the application needs to preserve between the
 * first and second requests of the OpenID login.  
 * 
 * @author JanRain, Inc.
 */
public class Token implements Serializable
{
    static final long serialVersionUID = -9130413740366967702L;
    private static final String cls = "com.janrain.openid.consumer.Token";
    private static Logger logger = Logger.getLogger(cls);

    private String consumerId;
    private String serverId;
    private String serverUrl;
    private long timestamp;
    private String serialized;
    private byte [] joined;
    private byte [] sig;

    public Token(byte [] key, String consumerId, String serverId,
                 String serverUrl)
    {
        this.consumerId = consumerId;
        this.serverId = serverId;
        this.serverUrl = serverUrl;

        timestamp = Util.getTimeStamp();
        join();

        sig = Util.hmacSha1(key, joined);

        byte [] full = new byte[joined.length + sig.length];
        System.arraycopy(sig, 0, full, 0, sig.length);
        System.arraycopy(joined, 0, full, sig.length, joined.length);

        serialized = Util.toBase64(full);
    }

    private Token()
    {
        // for static method below
    }

    public static Token fromSerialized(String serialized)
    {
        String mth = "fromSerialized";
        logger.entering(cls, mth, serialized);
        Token result = new Token();

        byte [] full = Util.fromBase64(serialized);

        if (full.length <= 20)
        {
            logger.logp(Level.INFO, cls, mth, "Invalid serialized form");
            logger.exiting(cls, mth, result);
            return result;
        }

        byte [] sig = new byte[20];
        byte [] joined = new byte[full.length - 20];
        System.arraycopy(full, 0, sig, 0, sig.length);
        System.arraycopy(full, sig.length, joined, 0, joined.length);

        result.serialized = serialized;
        result.sig = sig;

        String [] s = new String[4];
        int start = 0;
        int end = 0;

        try
        {
            for (int i = 0; i < s.length; i++)
            {
                while (end < joined.length && joined[end] != 0)
                    end++;
                s[i] = new String(joined, start, end - start, "UTF-8");

                if (end < joined.length)
                {
                    start = ++end; // skip the delimiter byte
                }
                else
                {
                    start = end;
                }
            }
        }
        catch (UnsupportedEncodingException e)
        {
            logger.log(Level.SEVERE, "No UTF-8?", e); // huh?
        }

        try
        {
            result.timestamp = Long.parseLong(s[0]);
        }
        catch (NumberFormatException e)
        {
            logger.logp(Level.INFO, cls, mth, "Unable to parse timestamp", e);
        }

        result.consumerId = s[1];
        result.serverId = s[2];
        result.serverUrl = s[3];

        result.join(); // recalculate joined, in case something didn't parse

        logger.exiting(cls, mth, result);
        return result;
    }

    private void join()
    {
        byte [][] working = new byte[4][];

        try
        {
            working[0] = String.valueOf(timestamp).getBytes("UTF-8");
            working[1] = String.valueOf(consumerId).getBytes("UTF-8");
            working[2] = String.valueOf(serverId).getBytes("UTF-8");
            working[3] = String.valueOf(serverUrl).getBytes("UTF-8");
        }
        catch (UnsupportedEncodingException e)
        {
            // This will still never happen
            logger.log(Level.SEVERE, "No UTF-8?", e);
            return;
        }

        int rlen = working.length - 1;
        for (int i = 0; i < working.length; i++)
            rlen += working[i].length;

        joined = new byte[rlen];

        int index = 0;

        for (int i = 0; i < working.length; i++)
        {
            System.arraycopy(working[i], 0, joined, index, working[i].length);
            index += working[i].length + 1; // adds the padding byte
        }
    }

    public String getConsumerId()
    {
        return consumerId;
    }

    public String getServerId()
    {
        return serverId;
    }

    public String getServerUrl()
    {
        return serverUrl;
    }

    public String getSerialized()
    {
        return serialized;
    }

    public long getTimeStamp()
    {
        return timestamp;
    }

    public boolean verify(byte [] key)
    {
        byte [] calculated = Util.hmacSha1(key, joined);
        return Arrays.equals(calculated, sig);
    }

    public boolean isStillValid(long lifetime)
    {
        return getTimeStamp() + lifetime > Util.getTimeStamp();
    }
}
