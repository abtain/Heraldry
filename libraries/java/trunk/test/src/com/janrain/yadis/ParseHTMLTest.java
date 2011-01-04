package com.janrain.yadis;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.UnsupportedEncodingException;

import com.janrain.url.FetchResponse;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

public class ParseHTMLTest extends TestCase
{
    private String expected;

    private FetchResponse in;

    public ParseHTMLTest(String testname, String expected, String input)
    {
        super(testname);
        String e = "UTF-8";
        try
        {
            in = new FetchResponse(-1, null, input.getBytes(e), e, null);
        }
        catch (UnsupportedEncodingException ue)
        {
            // won't happen
        }

        this.expected = expected;
    }

    public void runTest()
    {
        String actual = ParseHTML.findHTMLMeta(in);
        if (actual == null)
        {
            boolean passed = expected.equals("EOF") || expected.equals("None");
            assertTrue(expected + " isn't null", passed);
        }
        else
        {
            assertEquals(expected, actual);
        }
    }

    public static Test suite()
    {
        TestSuite suite = new TestSuite();

        InputStream is = null;
        try
        {
            is = ParseHTMLTest.class.getResourceAsStream("test1-parsehtml.txt");
            Reader r = new InputStreamReader(is, "UTF-8");
            BufferedReader br = new BufferedReader(r);

            int num = 0;
            boolean eof = false;
            while (!eof)
            {
                num++;
                StringBuffer c = new StringBuffer();

                while (true)
                {
                    String s = br.readLine();

                    if (s == null)
                    {
                        eof = true;
                        break;
                    }

                    if (s.equals("\f"))
                    {
                        break;
                    }

                    c.append(s);
                    c.append('\n');
                }
                if (!eof)
                {
                    String [] parts = c.toString().split("\n", 2);
                    suite.addTest(new ParseHTMLTest("case " + num, parts[0],
                            parts[1]));
                }
            }
        }
        catch (IOException e)
        {
            throw new RuntimeException(e);
        }
        finally
        {
            try
            {
                if (is != null)
                {
                    is.close();
                }
            }
            catch (IOException e)
            {
                // nothing to do
            }
        }

        return suite;
    }
}
