/*
 * LinkParserTest.java JUnit based test Created on December 20, 2005, 4:59 PM
 */

package com.janrain.openid.consumer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 * @author JanRain, Inc.
 */
public class LinkParserTest extends TestCase
{

    public LinkParserTest(String testName)
    {
        super(testName);
    }

    public static Test suite()
    {
        TestSuite suite = new TestSuite(LinkParserTest.class);

        return suite;
    }

    private static class Link
    {
        public boolean optional;
        public Map attrs = new HashMap();
        public Map optionalAttrs = new HashMap();

        public Link(String unparsed)
        {
            String [] parts = unparsed.split("\\s+");
            optional = parts[0].equals("Link*:");
            assertTrue(optional || parts[0].equals("Link:"));

            for (int i = 1; i < parts.length; i++)
            {
                String [] kv = parts[i].split("=", -1);
                Map addTo;
                if (kv[0].endsWith("*"))
                {
                    addTo = optionalAttrs;
                    kv[0] = kv[0].substring(0, kv[0].length() - 1);
                }
                else
                {
                    addTo = attrs;
                }
                addTo.put(kv[0], kv[1]);
            }
        }
    }

    private static class Case
    {
        public String desc;
        public String markup;
        public List links = new ArrayList();
        public List optionalLinks = new ArrayList();

        public Case(String unparsed)
        {
            String [] parts = unparsed.split("\n\n", 2);
            String header = parts[0];
            markup = parts[1];

            String [] lines = header.split("\n");
            desc = lines[0].substring(6);

            for (int i = 1; i < lines.length; i++)
            {
                Link l = new Link(lines[i]);
                if (l.optional)
                {
                    optionalLinks.add(l);
                }
                else
                {
                    links.add(l);
                }
            }
        }

        public static Case [] parseCases(String input)
        {
            String [] parts = input.split("\n\n\n", -1);

            String [] testLine = parts[0].split("\n", 2)[0].split(": ");
            assertEquals("Num Tests", testLine[0]);
            Case [] result = new Case[Integer.parseInt(testLine[1])];

            assertEquals(result.length + 2, parts.length);

            for (int i = 1; i < parts.length - 1; i++)
            {
                result[i - 1] = new Case(parts[i]);
            }

            return result;
        }

        public void test()
        {
            System.out.println("test: " + desc);
            List results = LinkParser.parseLinkAttrs(this.markup);

            int index = 0;
            int optindex = 0;

            for (Iterator res = results.iterator(); res.hasNext();)
            {
                LinkParser.LinkTag actual = (LinkParser.LinkTag)res.next();

                Link exp;
                if (index < links.size())
                {
                    exp = (Link)links.get(index);
                    if (linkEqualsFound(exp, actual))
                    {
                        index++;
                        continue;
                    }
                }

                boolean found = false;
                while (optindex < optionalLinks.size())
                {
                    exp = (Link)optionalLinks.get(optindex);
                    optindex++;
                    if (linkEqualsFound(exp, actual))
                    {
                        found = true;
                        break;
                    }
                }
                assertTrue(found);
            }
            assertEquals(links.size(), index);
        }

        public boolean linkEqualsFound(Link l, LinkParser.LinkTag t)
        {
            Set keys = t.getAttributeNames();
            int found = 0;
            for (Iterator it = keys.iterator(); it.hasNext();)
            {
                String name = it.next().toString();
                String value = t.getAttribute(name);

                if (value.equals(l.attrs.get(name)))
                {
                    found++;
                    continue;
                }

                if (!value.equals(l.optionalAttrs.get(name)))
                {
                    return false;
                }
            }
            return (found == t.size());
        }
    }

    /**
     * Test of parseLinkAttrs method, of class
     * com.janrain.openid.consumer.LinkParser.
     */
    public void testParseLinkAttrs()
    {
        System.out.println("testParseLinkAttrs");

        InputStream is = null;
        try
        {
            is = getClass().getResourceAsStream("linkparse.txt");
            if (is == null)
            {
                fail("Unable to load test data");
            }

            InputStreamReader ir = new InputStreamReader(is, "UTF-8");
            BufferedReader br = new BufferedReader(ir);

            char [] chunk = new char[1024];
            StringBuffer sb = new StringBuffer();

            for (int l = br.read(chunk); l >= 0; l = br.read(chunk))
            {
                sb.append(chunk, 0, l);
            }

            String input = sb.toString();
            Case [] cases = Case.parseCases(input);

            for (int i = 0; i < cases.length; i++)
            {
                cases[i].test();
            }
        }
        catch (IOException e)
        {
            fail("This shouldn't have happened");
        }
        finally
        {
            if (is != null)
            {
                try
                {
                    is.close();
                }
                catch (IOException e)
                {
                    // nothing to do
                }
            }
        }
    }
}
