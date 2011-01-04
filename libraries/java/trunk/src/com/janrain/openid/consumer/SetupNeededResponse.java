package com.janrain.openid.consumer;

/**
 * A response with a status of <code>StatusCode.SETUP_NEEDED</code>. This
 * response indicates that the server didn't have enough information to
 * determine the user's identity. This should only be returned if immediate mode
 * was used. If it is, the user should be redirected to the setup Url to finish
 * the login procedure.
 * 
 * @author JanRain, Inc.
 */
public class SetupNeededResponse extends Response
{
    private String setupUrl;

    public SetupNeededResponse(String identityUrl, String setupUrl)
    {
        super(StatusCode.SETUP_NEEDED, identityUrl);
        this.setupUrl = setupUrl;
    }

    /**
     * @return the setup Url that the server provided.
     */
    public String getSetupUrl()
    {
        return setupUrl;
    }
}
