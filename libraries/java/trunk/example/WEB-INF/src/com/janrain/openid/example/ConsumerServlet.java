package com.janrain.openid.example;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.janrain.openid.consumer.AuthRequest;
import com.janrain.openid.consumer.Consumer;
import com.janrain.openid.consumer.ErrorResponse;
import com.janrain.openid.consumer.Response;
import com.janrain.openid.consumer.StatusCode;
import com.janrain.openid.store.MemoryStore;

/*
 * This class is an example of a servlet using the com.janrain.openid package
 * 
 * The deployment descriptor maps this servlet to two urls in the context,
 * /submit and /return. /return is required to support GET requests, while
 * /submit could use GET, POST, or either. For simplicity, this example just
 * uses GET requests.
 */
public class ConsumerServlet extends HttpServlet
{
    private static final long serialVersionUID = -8426663656696891460L;
    private static final String storeKey = "openid.store";
    private static final String sessionKey = "openid.session";

    public void init(ServletConfig conf) throws ServletException
    {
        super.init(conf);
        ServletContext sc = conf.getServletContext();
        // if this was more than an example, it would load the store from disk
        // here, or use a db-backed store
        sc.setAttribute(storeKey, new MemoryStore());
    }

    public void destroy()
    {
        super.destroy();
        // if this was more than an example, it would write the store to disk
        // here if not using a db-backed store
    }

    /*
     * This method gets a <code>com.janrain.openid.consumer.Consumer</code>
     * instance appropriate for use in this servlet.
     */
    private Consumer getConsumer(HttpServletRequest req)
    {
        // pull the memory store out of the context
        MemoryStore ms = (MemoryStore)getServletContext()
                .getAttribute(storeKey);

        // fetch/create a session <code>Map</code> for the consumer's use
        Map session = (Map)req.getSession().getAttribute(sessionKey);
        if (session == null)
        {
            session = new HashMap();
            req.getSession().setAttribute(sessionKey, session);
        }

        return new Consumer(session, ms);
    }

    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException
    {
        String path = req.getServletPath();

        if (path.equals("/submit"))
        {
            // start the openid verification process
            doBegin(req, resp);
        }
        else if (path.equals("/return"))
        {
            // finish the openid verification process
            doReturn(req, resp);
        }
        else
        {
            // unexpected case.. Send them back to the starting page.
            resp.sendRedirect(resp.encodeRedirectURL("index.jsp"));
        }
    }

    /*
     * This method escapes characters in a string that can cause problems in
     * HTML
     */
    private String escapeAttr(String s)
    {
        if (s == null)
        {
            return "";
        }

        StringBuffer result = new StringBuffer();

        for (int i = 0; i < s.length(); i++)
        {
            char c = s.charAt(i);
            if (c == '<')
            {
                result.append("&lt;");
            }
            else if (c == '>')
            {
                result.append("&gt;");
            }
            else if (c == '&')
            {
                result.append("&amp;");
            }
            else if (c == '\"')
            {
                result.append("&quot;");
            }
            else if (c == '\'')
            {
                result.append("&#039;");
            }
            else if (c == '\\')
            {
                result.append("&#092;");
            }
            else
            {
                result.append(c);
            }
        }

        return result.toString();
    }

    /*
     * This method handles beginning openid authentication
     */
    private void doBegin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException
    {
        // get a consumer instance
        Consumer c = getConsumer(req);

        // get the submitted id field
        String id = req.getParameter("openid_url");

        // Create an Authrequest object from the submitted value
        AuthRequest ar;
        try
        {
            ar = c.begin(id);
        }
        catch (IOException e)
        {
            // An IOException indicates a failure, the message will contain some
            // information about it. Typically this means that the user's input
            // wasn't useable as an OpenID url. Handle by displaying the error
            // message and dropping the user back a the starting point
            req.setAttribute("message", error(e.getMessage()));
            req.getSession().setAttribute("savedId", escapeAttr(id));
            req.getRequestDispatcher("index.jsp").forward(req, resp);
            return;
        }

        // construct trust root and return to URLs.
        String port = "";
        if (req.getServerPort() != 80)
        {
            port = ":" + req.getServerPort();
        }
        String trustRoot = "http://" + req.getServerName() + port + "/";
        String cp = req.getContextPath();
        if (!cp.equals(""))
        {
            cp = cp.substring(1) + "/";
        }
        String returnTo = trustRoot + cp + "return";

        // send the user the redirect url to proceed with OpenID authentication
        String redirect = ar.redirectUrl(trustRoot, returnTo);
        resp.sendRedirect(redirect);
    }

    private String error(String msg)
    {
        return "<div class=\"error\">" + msg + "</div>";
    }

    private String alert(String msg)
    {
        return "<div class=\"alert\">" + msg + "</div>";
    }

    /*
     * This method handles the user's return to this site after having been
     * redirected to a remote site for authentication.
     */
    private void doReturn(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException
    {
        // get a Consumer instance
        Consumer c = getConsumer(req);

        // convert the argument map into the form the library uses with a handy
        // convenience function
        Map query = Consumer.filterArgs(req.getParameterMap());
        
        // Check the arguments to see what the response was.
        Response r = c.complete(query);
        
        // values for display in all cases
        String message;
        String savedId = escapeAttr(r.getIdentityUrl());

        StatusCode status = r.getStatus();

        // handle the various possibilites
        if (status == StatusCode.SUCCESS)
        {
            message = alert("Log in succeeded: " + savedId);
        }
        else if (status == StatusCode.CANCELLED)
        {
            message = alert("Log in cancelled");
        }
        else if (status == StatusCode.ERROR)
        {
            ErrorResponse er = (ErrorResponse)r;
            message = error("Error message from server: " + er.getMessage());
        }
        else if (status == StatusCode.FAILURE)
        {
            message = error("Log in failed - identity could not be verified");
        }
        else if (status == StatusCode.SETUP_NEEDED)
        {
            message = error("The server responded setup was needed, which shouldn't happen");
        }
        else
        {
            message = error("Unrecognized return value");
        }

        // display results to user
        req.setAttribute("message", message);
        req.getSession().setAttribute("savedId", savedId);
        req.getRequestDispatcher("index.jsp").forward(req, resp);
    }
}
