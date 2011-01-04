/*
 * Util.java Created on December 8, 2005, 9:34 AM
 */

package com.janrain.openid;

import gnu.inet.encoding.IDNA;
import gnu.inet.encoding.IDNAException;

import java.io.UnsupportedEncodingException;
import java.math.BigInteger;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.crypto.Mac;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

/**
 * This class provides several utility functions used withing the OpenID
 * libraries.
 * 
 * @author JanRain, Inc.
 */
public class Util
{
    private static final String cls = "com.janrain.openid.Util";
    private static Logger logger = Logger.getLogger(cls);
    private static URL base;
    private static SecureRandom srand = new SecureRandom();
    private static TimeKeeper timeKeeper = new TimeKeeper();

    static
    {
        try
        {
            // This seems like a reasonable sentinel value, but it is strange
            base = new URL("http://a.B.c.d.E.f.g.H.i.j.K.l/");
        }
        catch (MalformedURLException e)
        {
            // this can't happen
        }
    }

    public static class TimeKeeper
    {
        public long getTimeStamp()
        {
            return System.currentTimeMillis() / 1000L;
        }
    }

    public static void setTimeKeeper(TimeKeeper t)
    {
        timeKeeper = t;
    }

    public static long getTimeStamp()
    {
        return timeKeeper.getTimeStamp();
    }

    public static String numberToBase64(BigInteger i)
    {
        logger.entering(cls, "numberToBase64", i);
        String result = Base64.encodeBytes(i.toByteArray(),
                Base64.DONT_BREAK_LINES);
        logger.exiting(cls, "numberToBase64", result);
        return result;
    }

    public static BigInteger base64ToNumber(String s)
    {
        logger.entering(cls, "base64ToNumber", s);
        if (s == null)
        {
            logger.exiting(cls, "base64ToNumber", null);
            return null;
        }

        BigInteger result = new BigInteger(Base64.decode(s));
        logger.exiting(cls, "base64ToNumber", result);
        return result;
    }

    public static String toBase64(byte [] b)
    {
        logger.entering(cls, "toBase64", b);
        String result = Base64.encodeBytes(b, Base64.DONT_BREAK_LINES);
        logger.exiting(cls, "toBase64", result);
        return result;
    }

    public static byte [] fromBase64(String s)
    {
        logger.entering(cls, "fromBase64", s);
        byte [] result = Base64.decode(s);
        logger.exiting(cls, "fromBase64", result);
        return result;
    }

    public static String randomString(int length, char [] choices)
    {
        logger.entering(cls, "randomString", new Object[] {new Integer(length),
                choices});

        char [] result = new char[length];

        for (int i = 0; i < result.length; i++)
        {
            result[i] = choices[srand.nextInt(choices.length)];
        }

        String r = new String(result);
        logger.exiting(cls, "randomString", r);
        return r;
    }

    public static byte [] randomBytes(int length)
    {
        logger.entering(cls, "randomBytes", new Integer(length));
        byte [] result = new byte[length];
        srand.nextBytes(result);
        logger.exiting(cls, "randomBytes", result);
        return result;
    }

    public static byte [] hmacSha1(byte [] key, byte [] text)
    {
        try
        {
            logger.entering(cls, "hmacSha1", new Object[] {key, text});

            SecretKey sk = new SecretKeySpec(key, "HMACSHA1");
            Mac m = Mac.getInstance(sk.getAlgorithm());
            m.init(sk);
            byte [] result = m.doFinal(text);

            logger.exiting(cls, "hmacSha1", result);
            return result;
        }
        catch (InvalidKeyException e)
        {
            logger.log(Level.SEVERE, "Invalid key?", e);
            logger.exiting(cls, "hmacSha1", null);
            return null;
        }
        catch (NoSuchAlgorithmException e)
        {
            logger.log(Level.SEVERE, "JVM claims to not support HMACSHA1", e);
            logger.exiting(cls, "hmacSha1", null);
            return null;
        }
    }

    public static byte [] sha1(byte [] text)
    {
        try
        {
            logger.entering(cls, "sha1", text);

            MessageDigest d = MessageDigest.getInstance("SHA-1");

            byte [] result = d.digest(text);

            logger.exiting(cls, "sha1", result);
            return result;
        }
        catch (NoSuchAlgorithmException e)
        {
            logger.log(Level.SEVERE, "JVM claims to not support SHA1", e);
            logger.exiting(cls, "sha1", null);
            return null;
        }
    }

    public static String appendArgs(String url, Map args)
    {
        logger.entering(cls, "appendArgs", new Object[] {url, args});

        boolean hasQ = url.indexOf('?') >= 0;
        String result = url + (hasQ ? '&' : '?') + encodeArgs(args);

        logger.exiting(cls, "appendArgs", result);
        return result;
    }

    public static String encodeArgs(Map args)
    {
        logger.entering(cls, "encodeArgs", args);

        StringBuffer result = new StringBuffer();
        List l = new ArrayList(args.keySet());
        Collections.sort(l);

        try
        {
            Iterator it = l.iterator();
            while (it.hasNext())
            {
                String k = (String)it.next();
                String v = (String)args.get(k);

                result.append(URLEncoder.encode(k, "UTF-8"));
                result.append('=');
                result.append(URLEncoder.encode(v, "UTF-8"));
                result.append('&');
            }

            result.deleteCharAt(result.length() - 1);
        }
        catch (UnsupportedEncodingException e)
        {
            logger.severe("Failed to convert String to UTF-8. Broken.");
        }

        logger.exiting(cls, "encodeArgs", result.toString());
        return result.toString();
    }

    public static Map parseKVForm(String kvForm)
    {
        logger.entering(cls, "parseKVForm", kvForm);
        Map result = new HashMap();

        String [] lines = kvForm.split("\n");

        for (int i = 0; i < lines.length; i++)
        {
            String [] kv = lines[i].split(":", 2);
            if (kv.length == 2)
            {
                result.put(kv[0], kv[1]);
            }
            else
            {
                logger.info("Unexpected line in kv Form: " + lines[i]);
            }
        }

        logger.exiting(cls, "parseKVForm", result);
        return result;
    }

    public static String toKVForm(List fields, Map data)
    {
        logger.entering(cls, "toKVForm", new Object[] {fields, data});

        if (fields == null)
        {
            fields = new ArrayList(data.keySet());
            Collections.sort(fields);
        }

        StringBuffer work = new StringBuffer();
        Iterator it = fields.iterator();
        while (it.hasNext())
        {
            String k = (String)it.next();
            String v = (String)data.get(k);
            work.append(k);
            work.append(':');
            work.append(v);
            work.append('\n');
        }
        String result = work.toString();
        logger.exiting(cls, "toKVForm", result);
        return result;
    }

    public static String normalizeUrl(String url)
    {
        logger.entering(cls, "normalizeUrl", url);
        try
        {
            URL u = new URL(base, url);
            if (u.getHost().equals("a.B.c.d.E.f.g.H.i.j.K.l"))
            {
                url = "http://" + url;
            }

            u = new URL(base, url);

            String path;
            if (u.getPath().equals(""))
            {
                path = "/";
            }
            else
            {
                path = quoteMinimal(u.getPath());
            }

            u = new URL(u.getProtocol(), IDNA.toASCII(u.getHost()), path);
            String result = u.toString();
            logger.exiting(cls, "normalizeUrl", result);
            return result;
        }
        catch (MalformedURLException e)
        {
            logger.exiting(cls, "normalizeUrl", null);
            return null;
        }
        catch (IDNAException e)
        {
            logger.exiting(cls, "normalizeUrl", null);
            return null;
        }
    }

    private static String quoteMinimal(String s)
    {
        logger.entering(cls, "quoteMinimal", s);
        try
        {
            StringBuffer result = new StringBuffer();
            byte [] b = s.getBytes("UTF-8");
            for (int i = 0; i < b.length; i++)
            {
                int c = ((int)b[i]) & 0xFF;
                if (b[i] < (byte)' ')
                {
                    result.append('%');
                    result.append(Integer.toHexString(c).toUpperCase());
                }
                else
                {
                    result.append((char)c);
                }
            }
            logger.exiting(cls, "quoteMinimal", result.toString());
            return result.toString();
        }
        catch (UnsupportedEncodingException e)
        {
            // this will never happen
            logger.severe("Failed to convert String to UTF-8. Broken.");
            return null;
        }
    }
}
