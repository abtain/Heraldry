/*
 * DiffieHellman.java Created on December 7, 2005, 4:33 PM
 */

package com.janrain.openid;

import java.math.BigInteger;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Random;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * This class provides support for doing the Diffie-Hellman calculations used in
 * the OpenID protocol.
 * 
 * @author JanRain, Inc.
 */
public class DiffieHellman
{
    private static final String cls = "com.janrain.openid.DiffieHellman";
    private static Logger logger = Logger.getLogger(cls);

    public static final BigInteger DEFAULT_MOD = new BigInteger("15517289818"
            + "147369747123225776371553991572480196691540447970779531405762937"
            + "854191758065122742369818899372781615264663143856159582568818888"
            + "995127215884267541995034125870655654980358010487053768147672651"
            + "325574704076585747929129157233451064324509471500722962109419434"
            + "9783925984760375594985848253359305585439638443");

    public static final BigInteger DEFAULT_GEN = BigInteger.valueOf(2);

    private static final Random srand;
    static
    {
        Random r;
        try
        {
            r = SecureRandom.getInstance("SHA1PRNG");
        }
        catch (NoSuchAlgorithmException e)
        {
            // Can't do anything about it
            r = null;
        }
        srand = r;
    }

    private BigInteger modulus;
    private BigInteger generator;
    private BigInteger privateKey;
    private BigInteger publicKey;

    public DiffieHellman(BigInteger modulus, BigInteger generator)
    {
        logger
                .entering(cls, "DiffieHellman", new Object[] {modulus,
                        generator});

        if (srand == null)
        {
            IllegalStateException e = new IllegalStateException(
                    "No cryptographic quality pseudo-random source found");
            logger.throwing(cls, "DiffieHellman", e);
            throw e;
        }

        this.modulus = (modulus != null ? modulus : DEFAULT_MOD);
        this.generator = (generator != null ? generator : DEFAULT_GEN);

        int bits = this.modulus.bitLength();
        BigInteger max = this.modulus.subtract(BigInteger.ONE);
        while (true)
        {
            logger.fine("Generating a candidate private key");
            BigInteger pkey = new BigInteger(bits, srand);

            // if pKey is not in the valid range, try another one
            if (pkey.compareTo(max) >= 0)
            {
                logger.fine("Candidate key too large.");
                continue;
            }
            else if (pkey.compareTo(BigInteger.ONE) <= 0)
            {
                logger.fine("Candidate key too small.");
                continue;
            }

            logger.fine("Candidate key accepted.");
            setPrivateKey(pkey);
            break;
        }
        logger.exiting(cls, "DiffieHellman");
    }

    /**
     * Package-visible for use in tests
     */
    void setPrivateKey(BigInteger privateKey)
    {
        logger.entering(cls, "setPrivateKey", privateKey);
        this.privateKey = privateKey;
        publicKey = generator.modPow(privateKey, modulus);
        logger.exiting(cls, "setPrivateKey");
    }

    public DiffieHellman(String modulus, String generator)
    {
        this(Util.base64ToNumber(modulus), Util.base64ToNumber(generator));
    }

    public DiffieHellman()
    {
        this(DEFAULT_MOD, DEFAULT_GEN);
    }

    public BigInteger getSharedSecret(BigInteger composite)
    {
        logger.entering(cls, "getSharedSecret", composite);
        BigInteger result = composite.modPow(privateKey, modulus);
        logger.exiting(cls, "getSharedSecret", result);
        return result;
    }

    public BigInteger getPublicKey()
    {
        logger.entering(cls, "getPublicKey");
        logger.exiting(cls, "getPublicKey", publicKey);
        return publicKey;
    }

    public BigInteger getModulus()
    {
        logger.entering(cls, "getModulus");
        logger.exiting(cls, "getModulus", modulus);
        return modulus;
    }

    public BigInteger getGenerator()
    {
        logger.entering(cls, "getGenerator");
        logger.exiting(cls, "getGenerator", generator);
        return generator;
    }

    public boolean usesDefaults()
    {
        logger.entering(cls, "usesDefaults");
        boolean r = generator.equals(DEFAULT_GEN)
                && modulus.equals(DEFAULT_MOD);
        logger.exiting(cls, "usesDefaults", new Boolean(r));
        return r;
    }

    public byte [] xorSecret(BigInteger otherPublic, byte [] secret)
    {
        logger.entering(cls, "xorSecret", new Object[] {otherPublic, secret});

        BigInteger shared = otherPublic.modPow(privateKey, modulus);

        byte [] hashed = Util.sha1(shared.toByteArray());
        if (secret.length != hashed.length)
        {
            logger.log(Level.SEVERE, "invalid secret byte [] length", secret);
            logger.exiting(cls, "xorSecret", null);
            return null;
        }

        byte [] result = new byte[secret.length];
        for (int i = 0; i < result.length; i++)
        {
            result[i] = (byte)(hashed[i] ^ secret[i]);
        }

        logger.exiting(cls, "xorSecret", result);
        return result;
    }
}
