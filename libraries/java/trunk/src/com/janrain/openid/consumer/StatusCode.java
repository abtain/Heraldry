/*
 * StatusCode.java Created on January 25, 2006, 4:27 PM
 */

package com.janrain.openid.consumer;

import java.io.ObjectStreamException;
import java.io.Serializable;

/**
 * This class is a typesafe enumeration construct for enumerating the possible
 * final conditions of an OpenID request.
 * 
 * @author JanRain, Inc.
 */
public class StatusCode implements Serializable
{
    private static final long serialVersionUID = 2289980756918482315L;

    private static int nextOrdinal = 0;

    /**
     * This code indicates a successful authentication request
     */
    public static final StatusCode SUCCESS = new StatusCode("success");

    /**
     * This code indicates a failed authentication request
     */
    public static final StatusCode FAILURE = new StatusCode("failure");

    /**
     * This code indicates the server reported an error
     */
    public static final StatusCode ERROR = new StatusCode("error");

    /**
     * This code indicates that the user needs to do additional work to prove
     * their identity
     */
    public static final StatusCode SETUP_NEEDED = new StatusCode("setup needed");

    /**
     * This code indicates that the user cancelled their login request
     */
    public static final StatusCode CANCELLED = new StatusCode("cancelled");

    private static final StatusCode [] PRIVATE_VALUES = {SUCCESS, FAILURE,
            ERROR, SETUP_NEEDED, CANCELLED};

    private String name;

    private final int ordinal = nextOrdinal++;

    private StatusCode(String name)
    {
        this.name = name;
    }

    public String toString()
    {
        return name;
    }

    private Object readResolve() throws ObjectStreamException
    {
        return PRIVATE_VALUES[ordinal];
    }
}
