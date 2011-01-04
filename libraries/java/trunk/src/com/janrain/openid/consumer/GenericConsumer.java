package com.janrain.openid.consumer;

import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.janrain.openid.Association;
import com.janrain.openid.Util;
import com.janrain.openid.store.OpenIDStore;
import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;

/**
 * This class provides low-level OpenID logic to the Consumer class
 * 
 * @author JanRain, Inc.
 */
class GenericConsumer
{
    private static final String cls = "com.janrain.openid.consumer.OpenIDConsumer";
    private static Logger logger = Logger.getLogger(cls);

    private static long TOKEN_LIFETIME = 60 * 5; // five minutes in seconds
    private static int NONCE_LEN = 8;
    private static char [] NONCE_CHARS = ("abcdefghijklmnopqrstuvwzyzABCDEFGH"
            + "IJKLMNOPQRSTUVWXYZ0123456789").toCharArray();

    private static String NONCE_NAME = "nonce";

    private OpenIDStore store;

    public GenericConsumer(OpenIDStore store)
    {
        this.store = store;
    }

    public AuthRequest begin(OpenIDService s)
    {
        String nonce = createNonce();
        Token token = new Token(store.getAuthKey(), s.getIdentityUrl(), s
                .getDelegate(), s.getServerUrl());

        Association assoc = getAssociation(s.getServerUrl());
        AuthRequest request = new AuthRequest(token, assoc, s);
        request.addReturnToArg(NONCE_NAME, nonce);
        return request;
    }

    public Response complete(Map query, Token token)
    {
        String mode = ((String)query.get("openid.mode"));

        if (token == null)
        {
            return new FailureResponse(null, "No session state found.");
        }

        if (mode.equals("cancel"))
        {
            return new CancelResponse(token.getConsumerId());
        }
        else if (mode.equals("error"))
        {
            String error = ((String)query.get("openid.error"));
            return new ErrorResponse(token.getConsumerId(), error);
        }
        else if (mode.equals("id_res"))
        {
            Response r = doIdRes(query, token);
            if (r == null)
            {
                String message = "Failure connecting to server to verify login";
                return new FailureResponse(token.getConsumerId(), message);
            }

            if (r.getStatus() == StatusCode.SUCCESS)
            {
                return checkNonce(r, ((String)query.get(NONCE_NAME)));
            }
            else
            {
                return r;
            }
        }
        else
        {
            return new FailureResponse(token.getConsumerId(),
                    "Invalid openid.mode: " + mode);
        }
    }

    private static String urlRegex = ".*?://(.*?)(/.*?)?(\\?.*?)?(#.*?)?";
    private static Pattern urlPattern = Pattern.compile(urlRegex);

    private Response checkNonce(Response resp, String nonce)
    {
        SuccessResponse sr = (SuccessResponse)resp;
        String returnTo = sr.getReturnTo();

        Matcher m = urlPattern.matcher(returnTo);
        if (!m.matches())
        {
            String message = "Unable to parse the return_to url: " + returnTo;
            return new FailureResponse(sr.getIdentityUrl(), message);
        }

        String query = m.group(3);
        if (query == null)
        {
            String message = "The return_to url is missing a query section: "
                    + returnTo;
            return new FailureResponse(sr.getIdentityUrl(), message);
        }

        String [] args = query.split("[\\?\\&]");
        for (int i = 0; i < args.length; i++)
        {
            String [] kv = args[i].split("=", 2);
            if (kv.length != 2) continue;

            if (kv[0].equals(NONCE_NAME))
            {
                if (kv[1].equals(nonce))
                {
                    if (store.useNonce(nonce))
                    {
                        return resp;
                    }
                    else
                    {
                        String message = "unknown nonce: " + nonce;
                        return new FailureResponse(sr.getIdentityUrl(), message);
                    }
                }
                else
                {
                    break;
                }
            }
        }

        String message = "The return_to url's nonce does not equal the signed one: "
                + returnTo + " " + nonce;
        return new FailureResponse(sr.getIdentityUrl(), message);
    }

    private String createNonce()
    {
        String nonce = Util.randomString(NONCE_LEN, NONCE_CHARS);
        store.storeNonce(nonce);
        return nonce;
    }

    private Map makeKVPost(Map args, String serverUrl)
    {
        String mode = (String)args.get("openid.mode");
        String body = Util.encodeArgs(args);

        FetchResponse fr = HTTPFetcher.getFetcher().fetch(serverUrl, body);

        if (fr == null
                || (fr.getStatusCode() != 200 && fr.getStatusCode() != 400))
        {
            String error = "openid.mode=" + mode + "bad response from server "
                    + serverUrl + ": " + fr;
            logger.log(Level.INFO, error);
            return null;
        }

        Map result = Util.parseKVForm(fr.getContent());
        if (fr.getStatusCode() == 400)
        {
            String msg = (String)result.get("error");
            if (msg == null)
            {
                msg = "<no message from server>";
            }
            String error = "openid.mode=" + mode + ", error from server"
                    + serverUrl + ": " + msg;
            logger.log(Level.INFO, error);
            return null;
        }

        return result;
    }

    private Response doIdRes(Map query, Token token)
    {
        String userSetupUrl = (String)query.get("openid.user_setup_url");
        if (userSetupUrl != null)
        {
            return new SetupNeededResponse(token.getConsumerId(), userSetupUrl);
        }

        String returnTo = (String)query.get("openid.return_to");
        String serverId = (String)query.get("openid.identity");
        String assocHandle = (String)query.get("openid.assoc_handle");

        if (returnTo == null || serverId == null || assocHandle == null)
        {
            return new FailureResponse(token.getConsumerId(),
                    "Missing required field");
        }

        if (!serverId.equals(token.getServerId()))
        {
            return new FailureResponse(token.getConsumerId(),
                    "server id (delegate) mismatch");
        }

        String signed = (String)query.get("openid.signed");

        Association assoc = store.getAssociation(token.getServerUrl(),
                assocHandle);
        if (assoc == null)
        {
            // it's not an association we know about. fall back on dumb mode
            if (checkAuth(query, token.getServerUrl()))
            {
                return SuccessResponse.fromQuery(token.getConsumerId(), query,
                        signed);
            }
            else
            {
                return new FailureResponse(token.getConsumerId(),
                        "Server denied check_authentication");
            }
        }

        if (assoc.getRemainingLife() <= 0)
        {
            String msg = "Association with " + token.getServerUrl()
                    + " expired";
            return new FailureResponse(token.getConsumerId(), msg);
        }

        String sig = (String)query.get("openid.sig");
        if (sig == null || signed == null)
        {
            return new FailureResponse(token.getConsumerId(),
                    "Missing argument signature");
        }

        List signedList = Arrays.asList(signed.split(","));
        String vSig = assoc.sign(signedList, query);

        if (!vSig.equals(sig))
        {
            return new FailureResponse(token.getConsumerId(), "Bad Signature");
        }

        return SuccessResponse.fromQuery(token.getConsumerId(), query, signed);
    }

    private boolean checkAuth(Map query, String serverUrl)
    {
        Map request = createCheckAuthRequest(query);
        if (request == null)
        {
            return false;
        }

        Map response = makeKVPost(request, serverUrl);
        if (response == null)
        {
            return false;
        }

        return processCheckAuthResponse(response, serverUrl);
    }

    private Map createCheckAuthRequest(Map query)
    {
        String signed = (String)query.get("openid.signed");
        if (signed == null)
        {
            logger.log(Level.INFO, "no signature found, aborting checkAuth");
            return null;
        }

        String [] whitelist = {"assoc_handle", "sig", "signed",
                "invalidate_handle"};

        Set signedSet = new HashSet(Arrays.asList(whitelist));
        signedSet.addAll(Arrays.asList(signed.split(",")));

        Map result = new HashMap();
        Iterator it = query.entrySet().iterator();
        while (it.hasNext())
        {
            Map.Entry e = (Map.Entry)it.next();
            String k = (String)e.getKey();
            if (k.startsWith("openid.") && signedSet.contains(k.substring(7)))
            {
                result.put(k, e.getValue());
            }
        }

        result.put("openid.mode", "check_authentication");
        return result;
    }

    private boolean processCheckAuthResponse(Map response, String serverUrl)
    {
        String invalidateHandle = (String)response.get("invalidate_handle");
        if (invalidateHandle != null)
        {
            store.removeAssociation(serverUrl, invalidateHandle);
        }

        String isValid = (String)response.get("is_valid");
        if (isValid != null && isValid.equals("true"))
        {
            return true;
        }
        else
        {
            logger
                    .log(Level.INFO,
                            "Server responds that checkAuthentication call is not valid");
            return false;
        }
    }

    private Association getAssociation(String serverUrl)
    {
        if (store.isDumb())
        {
            return null;
        }

        Association assoc = store.getAssociation(serverUrl);

        if (assoc == null || assoc.getRemainingLife() < TOKEN_LIFETIME)
        {
            String sessionType = serverUrl.startsWith("https") ? "" : "DH-SHA1";
            Associator a = new Associator("HMAC-SHA1", sessionType);
            assoc = a.createAssociation(serverUrl);
            if (assoc != null)
            {
                store.storeAssociation(serverUrl, assoc);
            }
        }

        return assoc;
    }

    public static char [] getNonceChars()
    {
        return NONCE_CHARS;
    }

    public static void setNonceChars(char [] nonceChars)
    {
        NONCE_CHARS = nonceChars;
    }

    public static int getNonceLen()
    {
        return NONCE_LEN;
    }

    public static void setNonceLen(int nonceLen)
    {
        NONCE_LEN = nonceLen;
    }

    public static long getTokenLifetime()
    {
        return TOKEN_LIFETIME;
    }

    public static void setTokenLifetime(long tokenLifetime)
    {
        TOKEN_LIFETIME = tokenLifetime;
    }

    public static String getNonceName()
    {
        return NONCE_NAME;
    }

    public static void setNonceName(String nonceName)
    {
        GenericConsumer.NONCE_NAME = nonceName;
    }
}
