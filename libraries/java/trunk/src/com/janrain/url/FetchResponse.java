/*
 * FetchResponse.java Created on December 15, 2005, 11:03 AM
 */

package com.janrain.url;

import java.io.UnsupportedEncodingException;
import java.util.Map;

/**
 * @author JanRain, Inc.
 */
public class FetchResponse
{
    private int statusCode;
    private String finalUrl;
    private byte [] rawContent;
    private String encoding;
    private Map headers;

    public FetchResponse(int statusCode, String finalUrl, byte [] rawContent,
                         String encoding, Map headers)
    {
        this.statusCode = statusCode;
        this.finalUrl = finalUrl;
        this.rawContent = rawContent;
        this.encoding = encoding;
        this.headers = headers;
    }

    public int getStatusCode()
    {
        return statusCode;
    }

    public String getFinalUrl()
    {
        return finalUrl;
    }

    public byte [] getRawContent()
    {
        return rawContent;
    }

    public String getEncoding()
    {
        return encoding;
    }

    public String getContent()
    {
        try
        {
            return new String(rawContent, encoding);
        }
        catch (UnsupportedEncodingException e)
        {
            return null;
        }
    }

    public Map getHeaders()
    {
        return headers;
    }

    public String toString()
    {
        return "FetchResponse with status " + statusCode;
    }
}
