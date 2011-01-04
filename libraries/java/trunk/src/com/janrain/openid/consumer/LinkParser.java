/*
 * LinkParser.java Created on December 20, 2005, 4:57 PM
 */

package com.janrain.openid.consumer;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This class handles finding link tags if the library falls back on old-style
 * discovery.
 * 
 * @author JanRain, Inc.
 */
public class LinkParser
{
    private static final String cls = "com.janrain.openid.consumer.LinkParser";
    private static Logger logger = Logger.getLogger(cls);

    private static int flags = Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE
            | Pattern.DOTALL | Pattern.COMMENTS;

    private static Pattern removed = fromResource("removed.re");
    private static Pattern html = fromResource("html.re");
    private static Pattern head = fromResource("head.re");
    private static Pattern link = fromResource("link.re");
    private static Pattern attr = fromResource("attr.re");

    private static Pattern fromResource(String name)
    {
        logger.entering(cls, "fromResource", name);
        try
        {
            InputStream is = LinkParser.class.getResourceAsStream(name);
            if (is == null)
            {
                logger.log(Level.SEVERE, "Unable to locate resource " + name);
                logger.exiting(cls, "fromResource", null);
                return null;
            }
            Reader r = new InputStreamReader(is, "UTF-8");

            StringBuffer pat = new StringBuffer();

            char [] buffer = new char[1024];

            int c;
            while ((c = r.read(buffer, 0, buffer.length)) >= 0)
            {
                pat.append(buffer, 0, c);
            }

            Pattern result = Pattern.compile(pat.toString(), flags);
            logger.exiting(cls, "fromResource", result);
            return result;
        }
        catch (IOException e)
        {
            logger.log(Level.SEVERE, "Exception reading resource " + name, e);
            logger.exiting(cls, "fromResource", null);
            return null;
        }
    }

    private static Pattern ampRe = Pattern.compile("&amp;", flags);
    private static Pattern ltRe = Pattern.compile("&lt;", flags);
    private static Pattern gtRe = Pattern.compile("&gt;", flags);
    private static Pattern quotRe = Pattern.compile("&quot;", flags);

    private static String replaceEntities(String s)
    {
        String result = ltRe.matcher(s).replaceAll("<");
        result = gtRe.matcher(result).replaceAll(">");
        result = quotRe.matcher(result).replaceAll("\"");
        result = ampRe.matcher(result).replaceAll("&");

        return result;
    }

    public static List parseLinkAttrs(String input)
    {
        logger.entering(cls, "parseLinkAttrs", input);
        List result = new ArrayList();
        String stripped = removed.matcher(input).replaceAll("");

        Matcher htmlMatcher = html.matcher(stripped);
        if (!htmlMatcher.find() || htmlMatcher.group(2) == null)
        {
            logger.exiting(cls, "parseLinkAttrs", result);
            return result;
        }

        Matcher headMatcher = head.matcher(htmlMatcher.group(2));
        if (!headMatcher.find() || headMatcher.group(2) == null)
        {
            logger.exiting(cls, "parseLinkAttrs", result);
            return result;
        }

        String head = headMatcher.group(2);
        Matcher linkMatcher = link.matcher(head);

        while (linkMatcher.find())
        {
            Map m = new HashMap();

            Matcher attrMatcher = attr.matcher(head.substring(linkMatcher
                    .start() + 5));
            while (attrMatcher.find())
            {
                if (attrMatcher.group(5) != null)
                {
                    break;
                }

                String attrName = attrMatcher.group(1);
                String attrVal = attrMatcher.group(3) != null ? attrMatcher
                        .group(3) : attrMatcher.group(4);

                m.put(attrName.toLowerCase(), replaceEntities(attrVal));
            }
            result.add(new LinkTag(m));
        }

        logger.exiting(cls, "parseLinkAttrs", result);
        return result;
    }

    public static String findFirstHref(List linkList, String targetRel)
    {
        logger.entering(cls, "findFirstHref",
                new Object[] {linkList, targetRel});

        targetRel = targetRel.toLowerCase();

        Iterator it = linkList.iterator();
        while (it.hasNext())
        {
            LinkTag l = (LinkTag)it.next();

            String rel = l.getAttribute("rel");
            if (rel == null)
            {
                continue;
            }

            String [] pieces = rel.split("\\s+");
            for (int i = 0; i < pieces.length; i++)
            {
                if (pieces[i].toLowerCase().equals(targetRel))
                {
                    String result = l.getAttribute("href");
                    logger.exiting(cls, "findFirstHref", result);
                    return result;
                }
            }
        }

        logger.exiting(cls, "findFirstHref", null);
        return null;
    }

    public static class LinkTag
    {
        private Map attrs;

        private LinkTag(Map attrs)
        {
            // intentionally not defensively copying
            this.attrs = attrs;
        }

        public int size()
        {
            return attrs.size();
        }

        public String getAttribute(String name)
        {
            return (String)attrs.get(name);
        }

        public Set getAttributeNames()
        {
            return attrs.keySet();
        }
    }
}
