<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<jsp:useBean id="savedId" scope="session" class="java.lang.String" />
<jsp:useBean id="message" scope="request" class="java.lang.String" />
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>OpenID Consumer Example</title>
    <style type="text/css">
      * {
        font-family: verdana,sans-serif;
      }
      body {
        width: 50em;
        margin: 1em;
      }
      div {
        padding: .5em;
      }
      table {
        margin: none;
        padding: none;
      }
      .alert {
        border: 1px solid #e7dc2b;
        background: #fff888;
      }
      .error {
        border: 1px solid #ff0000;
        background: #ffaaaa;
      }
      #verify-form {
        border: 1px solid #777777;
        background: #dddddd;
        margin-top: 1em;
        padding-bottom: 0em;
      }
    </style>
  </head>
  <body>
    <h1>OpenID Consumer Example</h1>
    <p>
      This example consumer uses the <a
      href="http://www.openidenabled.com/">Java OpenID</a> library. It
      just verifies that the URL that you enter is your identity URL.
    </p>
    <% if (!message.equals("")) { %>
    ${message}
    <% } %>
    <div id="verify-form">
      <form method="get" action="submit">
        Identity&nbsp;URL:
        <input type="text" name="openid_url" value="${savedId}" />
        <input type="submit" value="Verify" />
      </form>
    </div>
  </body>
</html>
