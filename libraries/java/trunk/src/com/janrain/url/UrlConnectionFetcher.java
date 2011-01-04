/*
 * UrlConnectionFetcher.java Created on December 15, 2005, 1:01 PM
 */

package com.janrain.url;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.Charset;
import java.nio.charset.UnsupportedCharsetException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * @author JanRain, Inc.
 */
public class UrlConnectionFetcher extends HTTPFetcher
{
    private static final String cls = "com.janrain.openid.consumer.UrlConnectionFetcher";

    private static final Logger logger = Logger.getLogger(cls);

    private FetchResponse interpretResponse(HttpURLConnection conn)
            throws IOException
    {
        try
        {
            logger.entering(cls, "interpretResponse", conn);

            String charset;

            String contentType = conn.getContentType();
            if (contentType == null)
            {
                logger.log(Level.WARNING, "No content-type specified.");
                charset = "ISO-8859-1";
            }
            else
            {
                int csi = contentType.toLowerCase().indexOf("charset=");

                if (csi > -1)
                {
                    try
                    {
                        charset = Charset.forName(
                                contentType.substring(csi + 8)).name();
                    }
                    catch (UnsupportedCharsetException e)
                    {
                        logger.log(Level.WARNING,
                                "Unable to use given charset", e);
                        charset = "ISO-8859-1";
                    }
                }
                else
                {
                    logger.log(Level.WARNING, "Unable to find a charset");
                    charset = "ISO-8859-1";
                }
            }

            int code = conn.getResponseCode();

            ByteArrayOutputStream content;
            InputStream is = null;
            try
            {
                if (200 <= code && code < 300)
                {
                    is = conn.getInputStream();
                }
                else
                {
                    is = conn.getErrorStream();
                }

                content = new ByteArrayOutputStream();
                byte [] b = new byte[1024];
                int read;

                while ((read = is.read(b)) >= 0)
                    content.write(b, 0, read);
            }
            finally
            {
                if (is != null) is.close();
            }

            String finalUrl = conn.getURL().toString();
            byte [] rawContent = content.toByteArray();
            Map headers = new HashMap();

            Iterator it = conn.getHeaderFields().entrySet().iterator();
            while (it.hasNext())
            {
                Map.Entry e = (Map.Entry)it.next();
                String key = (String)e.getKey();
                if (key != null)
                {
                    key = key.toLowerCase();
                }
                List l = (List)e.getValue();
                String value = (String)l.get(l.size() - 1);
                headers.put(key, value);
            }

            FetchResponse result = new FetchResponse(code, finalUrl,
                    rawContent, charset, headers);
            logger.exiting(cls, "interpretResponse", result);
            return result;
        }
        catch (IOException e)
        {
            logger.throwing(cls, "interpretResponse", e);
            throw e;
        }
        catch (NumberFormatException nfe)
        {
            IOException ioe = new IOException("Bad server status response");
            ioe.initCause(nfe);
            logger.throwing(cls, "interpretResponse", ioe);
            throw ioe;
        }
    }

    public FetchResponse fetch(String url, String data, Map headers)
    {
        logger.entering(cls, "fetch", new Object[] {url, data, headers});

        URL u;
        try
        {
            u = new URL(url);
        }
        catch (MalformedURLException e)
        {
            logger.log(Level.WARNING, "Exception parsing input URL", e);
            logger.exiting(cls, "fetch", null);
            return null;
        }

        try
        {
            HttpURLConnection conn = (HttpURLConnection)u.openConnection();

            boolean post = data != null;
            if (post)
            {
                conn.setDoOutput(true);
                conn.setRequestProperty("Content-Encoding", "UTF-8");
            }

            conn.connect();

            if (post)
            {
                OutputStream os = conn.getOutputStream();
                os.write(data.getBytes("UTF-8"));
                os.close();
            }

            FetchResponse result = interpretResponse(conn);

            logger.exiting(cls, "fetch", result);
            return result;
        }
        catch (IOException e)
        {
            logger.log(Level.WARNING, "IO error fetching URL", e);
            logger.exiting(cls, "fetch", null);
            return null;
        }
        catch (ClassCastException e)
        {
            logger.log(Level.WARNING, "Not an HTTP or HTTPS URL", e);
            logger.exiting(cls, "fetch", null);
            return null;
        }
    }
}
