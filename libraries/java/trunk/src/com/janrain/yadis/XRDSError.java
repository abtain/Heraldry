package com.janrain.yadis;

public class XRDSError extends Exception
{
    private static final long serialVersionUID = -8010668352742513893L;

    public XRDSError()
    {
        super();
    }

    public XRDSError(String message, Throwable cause)
    {
        super(message, cause);
    }

    public XRDSError(String message)
    {
        super(message);
    }

    public XRDSError(Throwable cause)
    {
        super(cause);
    }

}
