package com.janrain.yadis;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.UnsupportedEncodingException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.swing.text.MutableAttributeSet;
import javax.swing.text.html.HTML;
import javax.swing.text.html.HTMLEditorKit;
import javax.swing.text.html.HTML.Tag;

import com.janrain.url.FetchResponse;

public class ParseHTML
{
    private static String entityRE = "&#x([a-f0-9]+);";

    private static Pattern entityPattern = Pattern.compile(entityRE,
            Pattern.CASE_INSENSITIVE);

    private static String hexEntities(String s)
    {
        Matcher m = entityPattern.matcher(s);
        StringBuffer result = new StringBuffer();
        while (m.find())
        {
            String replacement;
            try
            {
                int i = Integer.parseInt(m.group(1), 16);
                replacement = "&#" + String.valueOf(i) + ";";
            }
            catch (NumberFormatException e)
            {
                replacement = m.group();
            }

            m.appendReplacement(result, replacement);
        }
        m.appendTail(result);

        return result.toString();
    }

    private static class Accessor extends HTMLEditorKit
    {
        private static final long serialVersionUID = 2721756213643570638L;

        public Parser getParser()
        {
            return super.getParser();
        }
    }

    private static class YadisHTMLParser extends HTMLEditorKit.ParserCallback
    {
        private static final int top = 0;
        private static final int html = 1;
        private static final int head = 2;
        private static final int found = 3;
        private static final int terminated = 4;

        private int state;
        private String result;

        public String getResult()
        {
            return result;
        }

        public YadisHTMLParser()
        {
            state = top;
        }

        public void handleEndTag(Tag t, int pos)
        {
            if (t == HTML.Tag.HEAD || t == HTML.Tag.BODY || t == HTML.Tag.HTML)
            {
                state = terminated;
            }
        }

        public void handleSimpleTag(Tag t, MutableAttributeSet a, int pos)
        {
            if (state == head && t == HTML.Tag.META)
            {
                String httpEquiv = (String)a
                        .getAttribute(HTML.Attribute.HTTPEQUIV);

                if (Constants.HEADER_NAME.equalsIgnoreCase(httpEquiv))
                {
                    String content = (String)a
                            .getAttribute(HTML.Attribute.CONTENT);
                    result = content;
                    state = found;
                }
            }
            else
            {
                handleEndTag(t, pos);
            }
        }

        public void handleStartTag(Tag t, MutableAttributeSet a, int pos)
        {
            if (t == HTML.Tag.BODY)
            {
                state = terminated;
            }

            if (state == top)
            {
                if (t == HTML.Tag.HEAD)
                {
                    state = head;
                }
                else if (t == HTML.Tag.HTML)
                {
                    state = html;
                }
            }
            else if (state == html)
            {
                if (t == HTML.Tag.HEAD)
                {
                    state = head;
                }
                else if (t == HTML.Tag.HTML)
                {
                    state = terminated;
                }
            }
            else if (state == head)
            {
                if (t == HTML.Tag.HEAD || t == HTML.Tag.HTML)
                {
                    state = terminated;
                }
            }
            else
            {
                state = terminated;
            }
        }

    }

    public static String findHTMLMeta(FetchResponse resp)
    {
        YadisHTMLParser cb = new YadisHTMLParser();

        try
        {
            Reader r = new StringReader(hexEntities(resp.getContent()));
            new Accessor().getParser().parse(r, cb, false);
        }
        catch (UnsupportedEncodingException e)
        {
            // nothing to do
        }
        catch (IOException e)
        {
            // nothing to do
        }

        return cb.getResult();
    }

}
