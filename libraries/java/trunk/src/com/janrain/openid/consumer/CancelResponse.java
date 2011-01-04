package com.janrain.openid.consumer;

/**
 * A response with a status of <code>StatusCode.CANCELLED</code>. This
 * response indicates that the user cancelled their login request.
 * 
 * @author JanRain, Inc.
 */
public class CancelResponse extends Response
{
    public CancelResponse(String identityUrl)
    {
        super(StatusCode.CANCELLED, identityUrl);
    }
}
