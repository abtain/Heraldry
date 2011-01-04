package com.janrain.url;

import java.util.Map;

/**
 * @author JanRain, Inc.
 */
public abstract class HTTPFetcher
{
    private static HTTPFetcher f;

    public static HTTPFetcher getFetcher()
    {
        if (f == null)
        {
            return f = new UrlConnectionFetcher();
        }
        else
        {
            return f;
        }
    }

    public static void setFetcher(HTTPFetcher fetcher)
    {
        f = fetcher;
    }

    public FetchResponse fetch(String url)
    {
        return fetch(url, null, null);
    }

    public FetchResponse fetch(String url, String body)
    {
        return fetch(url, body, null);
    }

    public FetchResponse fetch(String url, Map headers)
    {
        return fetch(url, null, headers);
    }

    public abstract FetchResponse fetch(String url, String body, Map headers);

}
