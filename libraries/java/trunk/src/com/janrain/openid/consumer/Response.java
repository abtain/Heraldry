package com.janrain.openid.consumer;

/**
 * This is the superclass for the various responses the OpenID library can
 * result in. Subclasses contain more information about what went on in their
 * specific case.
 * 
 * @author JanRain, Inc.
 */
public abstract class Response
{
    private StatusCode status;
    private String identityUrl;

    protected Response(StatusCode status, String identityUrl)
    {
        this.status = status;
        this.identityUrl = identityUrl;
    }

    /**
     * @return the status of this Response, for easier branching based on status
     *         than checking for a particular subclass being returned
     */
    public StatusCode getStatus()
    {
        return status;
    }

    /**
     * @return the identity url the user was asserting, or <code>null</code>
     *         if unknown.
     */
    public String getIdentityUrl()
    {
        return identityUrl;
    }
}
