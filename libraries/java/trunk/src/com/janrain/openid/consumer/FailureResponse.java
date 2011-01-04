package com.janrain.openid.consumer;

/**
 * A response with a status of <code>StatusCode.FAILURE</code>. This
 * response indicates that the user's login attempt wasn't valid.
 * 
 * @author JanRain, Inc.
 */public class FailureResponse extends Response
{
    private String message;

    public FailureResponse(String identityUrl, String message)
    {
        super(StatusCode.FAILURE, identityUrl);
        this.message = message;
    }

    /**
     * @return a short description of why the login attempt was invalid
     */
    public String getMessage()
    {
        return message;
    }
}
