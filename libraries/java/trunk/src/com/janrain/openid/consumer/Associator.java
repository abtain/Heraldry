/*
 * Associator.java Created on February 8, 2006, 1:00 PM
 */

package com.janrain.openid.consumer;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.janrain.openid.DiffieHellman;
import com.janrain.openid.Association;
import com.janrain.openid.Util;
import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;

/**
 * This class contains the logic for creating new associations.
 * 
 * @author JanRain, Inc.
 */
public class Associator
{
    private static final String cls = "com.janrain.openid.consumer.Associator";
    private static final Logger logger = Logger.getLogger(cls);
    private static Set associationTypes = new HashSet();
    private static Map sessionTypes = new HashMap();

    static
    {
        associationTypes.add("HMAC-SHA1");

        sessionTypes.put("", DefaultSessionHandler.class);
        sessionTypes.put("DH-SHA1", DhSha1SessionHandler.class);
    }

    private static class AssociationBuilder
    {
        private boolean dirty = true;
        private Association cached;
        private String handle;
        private byte [] secret;
        private long lifetime;
        private String assocType;
        private String error;

        public void setHandle(String handle)
        {
            dirty = true;
            this.handle = handle;
        }

        public void setSecret(byte [] secret)
        {
            dirty = true;
            this.secret = secret;
        }

        public void setLifetime(long lifetime)
        {
            dirty = true;
            this.lifetime = lifetime;
        }

        public void setAssocType(String assocType)
        {
            dirty = true;
            this.assocType = assocType;
        }

        public void setError(String error)
        {
            dirty = true;
            this.error = error;
        }

        public Association getAssociation()
        {
            if (!dirty) return cached;

            if (error != null)
            {
                throw new IllegalStateException(error);
            }

            cached = new Association(handle, secret, lifetime, assocType);
            dirty = false;
            return cached;
        }
    }

    private abstract class SessionHandler
    {
        public SessionHandler()
        {
            // do nothing
        }

        public Map buildArgs()
        {
            Map args = new HashMap();

            args.put("openid.mode", "associate");
            args.put("openid.assoc_type", assocType);
            args.put("openid.session_type", sessionType);

            return args;
        }

        public AssociationBuilder parseResponse(Map response)
        {

            AssociationBuilder result = new AssociationBuilder();

            String assocType = (String)response.get("assoc_type");
            if (assocType == null || !associationTypes.contains(assocType))
            {
                logger.log(Level.INFO, "Unknown association type", assocType);
                result.setError("Unknown association type: " + assocType);
            }
            result.setAssocType(assocType);

            String assocHandle = (String)response.get("assoc_handle");
            if (assocHandle == null)
            {
                String err = "No association handle provided";
                logger.log(Level.INFO, err);
                result.setError(err);
            }
            result.setHandle(assocHandle);

            try
            {
                result.setLifetime(Long.parseLong((String)response
                        .get("expires_in")));
            }
            catch (NullPointerException e)
            {
                String err = "No expires_in field provided";
                logger.log(Level.INFO, err);
                result.setError(err);
            }
            catch (NumberFormatException e)
            {
                String err = "expires_in field didn't contain an integer";
                logger.log(Level.INFO, err);
                result.setError(err);
            }

            return result;
        }
    }

    private class DefaultSessionHandler extends SessionHandler
    {
        public DefaultSessionHandler()
        {
        }

        public Map buildArgs()
        {
            return super.buildArgs();
        }

        public AssociationBuilder parseResponse(Map response)
        {
            AssociationBuilder result = super.parseResponse(response);

            String encMacKey = (String)response.get("mac_key");
            if (encMacKey == null)
            {
                String err = "mac_key field required and missing";
                logger.log(Level.INFO, err);
                result.setError(err);
            }
            result.setSecret(Util.fromBase64(encMacKey));

            return result;
        }
    }

    private class DhSha1SessionHandler extends SessionHandler
    {
        public DhSha1SessionHandler()
        {
        }

        private DiffieHellman dh;

        public Map buildArgs()
        {
            Map args = super.buildArgs();
            dh = new DiffieHellman();

            args.put("openid.dh_consumer_public", Util.numberToBase64(dh
                    .getPublicKey()));

            if (!dh.usesDefaults())
            {
                args.put("openid.dh_modulus", Util.numberToBase64(dh
                        .getModulus()));
            }

            return args;
        }

        public AssociationBuilder parseResponse(Map response)
        {
            String sessionType = (String)response.get("session_type");
            if (sessionType == null)
            {
                return new DefaultSessionHandler().parseResponse(response);
            }

            AssociationBuilder result = super.parseResponse(response);

            if (!sessionType.equals("DH-SHA1"))
            {
                String err = "Unknown session type: " + sessionType;
                logger.log(Level.INFO, err);
                result.setError(err);
                return result;
            }

            String serverPublic = (String)response.get("dh_server_public");
            if (serverPublic == null)
            {
                String err = "Server public key absent";
                logger.log(Level.INFO, err);
                result.setError(err);
                return result;
            }

            BigInteger spub = Util.base64ToNumber(serverPublic);

            String b64MacKey = (String)response.get("enc_mac_key");
            if (b64MacKey == null)
            {
                String err = "Server public key absent";
                logger.log(Level.INFO, err);
                result.setError(err);
                return result;
            }

            byte [] secret = dh.xorSecret(spub, Util.fromBase64(b64MacKey));
            if (secret == null)
            {
                String err = "Unable to calculate secret";
                logger.log(Level.INFO, err);
                result.setError(err);
            }

            result.setSecret(secret);
            return result;
        }
    }

    private String assocType;
    private String sessionType;

    public Associator(String associationType, String preferredSessionType)
    {
        if (!associationTypes.contains(associationType))
        {
            throw new IllegalArgumentException(
                    "The only currently-supported association type is HMAC-SHA1");
        }
        assocType = associationType;

        if (!sessionTypes.containsKey(preferredSessionType))
        {
            throw new IllegalArgumentException("Not a valid session type.");
        }
        sessionType = preferredSessionType;
    }

    public Associator()
    {
        this("HMAC-SHA1", "DH-SHA1");
    }

    public Association createAssociation(String serverUrl)
    {
        logger.entering(cls, "createAssociation", serverUrl);

        HTTPFetcher fetcher = HTTPFetcher.getFetcher();
        SessionHandler sess = getSessionHandler();
        Map args = sess.buildArgs();

        Map response = getServerResponse(fetcher, serverUrl, args);

        if (response == null)
        {
            logger.exiting(cls, "createAssociation", null);
            return null;
        }

        AssociationBuilder res = sess.parseResponse(response);

        try
        {
            Association result = res.getAssociation();
            logger.exiting(cls, "createAssociation", result);
            return result;
        }
        catch (IllegalStateException e)
        {
            logger.log(Level.INFO, "Exception building Association", e);
            logger.exiting(cls, "createAssociation", null);
            return null;
        }
    }

    private Map getServerResponse(HTTPFetcher fetcher, String serverUrl,
            Map args)
    {
        logger.entering(cls, "getServerResponse", new Object[] {fetcher,
                serverUrl, args});

        String body = Util.encodeArgs(args);
        FetchResponse fr = fetcher.fetch(serverUrl, body);
        if (fr == null || fr.getStatusCode() != 200)
        {
            logger.log(Level.INFO,
                    "Fetch failure attempting to make association", fr);
            logger.exiting(cls, "getServerResponse", null);
            return null;
        }

        return Util.parseKVForm(fr.getContent());
    }

    private SessionHandler getSessionHandler()
    {
        logger.entering(cls, "getSessionHandler");
        Class c = (Class)sessionTypes.get(sessionType);
        try
        {
            Constructor cons = c.getConstructors()[0];
            Object [] initArgs = {this};
            SessionHandler result = (SessionHandler)cons.newInstance(initArgs);
            logger.exiting(cls, "getSessionHandler", result);
            return result;
        }
        catch (InstantiationException e)
        {
            logger.log(Level.SEVERE,
                    "Unexpected exception create a session handler.", e);
        }
        catch (IllegalAccessException e)
        {
            logger.log(Level.SEVERE,
                    "Unexpected exception create a session handler.", e);
        }
        catch (InvocationTargetException e)
        {
            logger.log(Level.SEVERE,
                    "Unexpected exception create a session handler.", e);
        }
        logger.exiting(cls, "getSessionHandler", null);
        return null;
    }
}
