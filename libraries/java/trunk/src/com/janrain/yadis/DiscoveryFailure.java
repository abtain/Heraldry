package com.janrain.yadis;

public class DiscoveryFailure extends Exception
{
    private static final long serialVersionUID = 7818888610216271759L;

    public DiscoveryFailure()
    {
        super();
    }

    public DiscoveryFailure(String message, Throwable cause)
    {
        super(message, cause);
    }

    public DiscoveryFailure(String message)
    {
        super(message);
    }

    public DiscoveryFailure(Throwable cause)
    {
        super(cause);
    }

}
