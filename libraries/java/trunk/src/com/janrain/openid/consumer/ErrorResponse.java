package com.janrain.openid.consumer;

/**
 * A response with a status of <code>StatusCode.ERROR</code>. This
 * response indicates the identity server sent an error message.
 * 
 * @author JanRain, Inc.
 */public class ErrorResponse extends Response
{
    private String message;

    public ErrorResponse(String identityUrl, String message)
    {
        super(StatusCode.ERROR, identityUrl);
        this.message = message;
    }

    /**
     * @return the error message sent by the server
     */
    public String getMessage()
    {
        return message;
    }
}
