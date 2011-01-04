package com.janrain.yadis;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

import com.janrain.url.FetchResponse;
import com.janrain.url.HTTPFetcher;

public class DiscoveryResultTest extends TestCase
{
    public static Test suite()
    {
        TestSuite suite = new TestSuite();
        suite.addTest(new SecondGetTester());

        DiscoveryTest [] tests = {
                new DiscoveryTest(true, "equiv", "equiv", "xrds"),
                new DiscoveryTest(true, "header", "header", "xrds"),
                new DiscoveryTest(true, "lowercase_header", "lowercase_header",
                        "xrds"),
                new DiscoveryTest(true, "xrds", "xrds", "xrds"),
                new DiscoveryTest(true, "xrds_ctparam", "xrds_ctparam",
                        "xrds_ctparam"),
                new DiscoveryTest(true, "xrds_ctcase", "xrds_ctcase",
                        "xrds_ctcase"),
                new DiscoveryTest(false, "xrds_html", "xrds_html", "xrds_html"),
                new DiscoveryTest(true, "redir_equiv", "equiv", "xrds"),
                new DiscoveryTest(true, "redir_header", "header", "xrds"),
                new DiscoveryTest(true, "redir_xrds", "xrds", "xrds"),
                new DiscoveryTest(false, "redir_xrds_html", "xrds_html",
                        "xrds_html"),
                new DiscoveryTest(true, "redir_redir_equiv", "equiv", "xrds"),
                new DiscoveryTest(false, "404_server_response", null, null),
                new DiscoveryTest(false, "404_with_header", null, null),
                new DiscoveryTest(false, "404_with_meta", null, null),
                new DiscoveryTest(false, "201_server_response", null, null),
                new DiscoveryTest(false, "500_server_response", null, null)};

        for (int i = 0; i < tests.length; i++)
        {
            suite.addTest(tests[i]);
        }

        return suite;
    }

    private static class SecondGetTester extends TestCase
    {
        public SecondGetTester()
        {
            super("testSecondGet");
        }

        class Fetcher extends HTTPFetcher
        {
            private int count = 0;

            public FetchResponse fetch(String url, String body, Map headers)
            {
                if (++count == 1)
                {
                    Map rh = new HashMap();
                    rh.put("X-XRDS-Location".toLowerCase(),
                            "http://unittest/404");
                    return new FetchResponse(200, url, new byte[0], "UTF-8", rh);
                }
                else
                {
                    return new FetchResponse(404, url, new byte[0], "UTF-8",
                            null);
                }
            }
        }

        public void runTest()
        {
            HTTPFetcher old = HTTPFetcher.getFetcher();
            HTTPFetcher.setFetcher(new Fetcher());

            String uri = "http://something.unittest/";
            try
            {
                DiscoveryResult.fromURI(uri);
                fail("DiscoveryFailure wasn't thrown");
            }
            catch (DiscoveryFailure d)
            {
                // this is the expected case
            }

            HTTPFetcher.setFetcher(old);
        }
    }

    private static class DiscoveryTest extends TestCase
    {
        private static final String baseUrl = "http://invalid.unittest/";

        private static String exampleXrds = read("example-xrds.xml");
        private static String testData = read("test1-discover.txt");
        private static Map parsedTests = new HashMap();
        private static int count = 1;

        private static String read(String resourceName)
        {
            InputStream is = null;
            try
            {
                is = DiscoveryTest.class.getResourceAsStream(resourceName);
                BufferedReader br = new BufferedReader(new InputStreamReader(
                        is, "UTF-8"));

                char [] buf = new char[1024];
                StringBuffer result = new StringBuffer();
                int c;
                while ((c = br.read(buf)) >= 0)
                {
                    result.append(buf, 0, c);
                }
                return result.toString();
            }
            catch (IOException e)
            {
                throw new RuntimeException(e);
            }
            finally
            {
                try
                {
                    if (is != null) is.close();
                }
                catch (IOException e)
                {
                    // ignore
                }
            }
        }

        private static String getData(String name) throws IOException
        {
            if (parsedTests.isEmpty())
            {
                String [] cases = testData.split("\f\n");
                for (int i = 0; i < cases.length; i++)
                {
                    String [] dat = cases[i].split("\n", 2);
                    parsedTests.put(dat[0], dat[1]);
                }
            }
            return (String)parsedTests.get(name);
        }

        private String inputName;
        private String idName;
        private String resultName;
        private boolean success;

        private HTTPFetcher old;
        private String inputUrl;
        private DiscoveryResult expected;

        class Fetcher extends HTTPFetcher
        {
            private Pattern statusHeaderPat = Pattern.compile(
                    "Status: (\\d+) .*?$", Pattern.MULTILINE);

            private FetchResponse makeResponse(String finalUrl, String data)
            {
                Matcher m = statusHeaderPat.matcher(data);
                String [] parts = data.split("\n\n", 2);
                Map headers = new HashMap();
                String [] hlines = parts[0].split("\n");
                for (int i = 0; i < hlines.length; i++)
                {
                    String [] kv = hlines[i].split(":", 2);
                    String k = kv[0].toLowerCase().trim();
                    String v = kv[1].trim();
                    headers.put(k, v);
                }
                m.find();
                int status = Integer.parseInt(m.group(1));
                try
                {
                    return new FetchResponse(status, finalUrl, parts[1]
                            .getBytes("UTF-8"), "UTF-8", headers);
                }
                catch (UnsupportedEncodingException e)
                {
                    throw new RuntimeException("This won't happen");
                }
            }

            public FetchResponse fetch(String url, String body, Map headers)
            {
                try
                {
                    Pattern p = Pattern.compile(".*?//.*?/(.*)");
                    String currentUrl = url;
                    while (true)
                    {
                        Matcher m = p.matcher(currentUrl);
                        m.matches();
                        String path = m.group(1);
                        String data = generateSample(path);
                        if (data == null)
                        {
                            return new FetchResponse(404, currentUrl,
                                    new byte[0], "UTF-8", new HashMap());
                        }
                        FetchResponse response = makeResponse(currentUrl, data);
                        int status = response.getStatusCode();
                        if (status == 301 || status == 302 || status == 303
                                || status == 307)
                        {
                            currentUrl = (String)response.getHeaders().get(
                                    "location");
                        }
                        else
                        {
                            return response;
                        }
                    }
                }
                catch (IOException e)
                {
                    return null;
                }
            }
        }

        public DiscoveryTest(boolean success, String inputName, String idName,
                             String resultName)
        {
            super("DiscoveryTest " + ++count + ": " + inputName);
            this.inputName = inputName;
            this.idName = idName;
            this.resultName = resultName;
            this.success = success;
        }

        private static String generateSample(String sampleName)
                throws IOException
        {
            String template = getData(sampleName);

            String mangledExample = exampleXrds.replaceAll("\\$", "\\\\\\$");

            template = template.replaceAll("URL_BASE/", baseUrl);
            template = template.replaceAll("<XRDS Content>", mangledExample);
            template = template.replaceAll("YADIS_HEADER",
                    Constants.HEADER_NAME);
            template = template.replaceAll("NAME", sampleName);

            return template;
        }

        protected void setUp() throws Exception
        {
            old = HTTPFetcher.getFetcher();
            HTTPFetcher.setFetcher(new Fetcher());

            inputUrl = baseUrl + inputName;
            if (idName == null)
            {
                assertNull(resultName);
                return;
            }
            String sample = generateSample(resultName);
            String [] parts = sample.split("\n\n", 2);
            String [] headerLines = parts[0].split("\n");

            String ctype = null;
            for (int i = 0; i < headerLines.length; i++)
            {
                if (headerLines[i].startsWith("Content-Type:"))
                {
                    ctype = headerLines[i].split(":", 2)[1].trim();
                    break;
                }
            }
            expected = new DiscoveryResult(inputUrl);
            expected.normalizedUri = baseUrl + idName;
            if (success)
            {
                expected.xrdsUri = baseUrl + resultName;
            }
            expected.contentType = ctype;
            expected.content = parts[1].getBytes("UTF-8");
            expected.encoding = "UTF-8";
        }

        protected void tearDown() throws Exception
        {
            HTTPFetcher.setFetcher(old);
        }

        protected void runTest() throws Throwable
        {
            if (expected == null)
            {
                try
                {
                    DiscoveryResult.fromURI(inputUrl);
                    fail("Should have thrown a discovery error");
                }
                catch (DiscoveryFailure d)
                {
                    // expected
                }
            }
            else
            {
                DiscoveryResult result = DiscoveryResult.fromURI(inputUrl);
                assertEquals(inputUrl, result.getRequestUri());
                assertEquals(expected, result);
            }
        }
    }
}
