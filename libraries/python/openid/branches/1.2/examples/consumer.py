#!/usr/bin/env python
"""
Simple example for an OpenID consumer.

Once you understand this example you'll know the basics of OpenID
and using the Python OpenID library. You can then move on to more
robust examples, and integrating OpenID into your application.
"""
__copyright__ = 'Copyright 2005, Janrain, Inc.'

from Cookie import SimpleCookie
import cgi
import urlparse
import cgitb
import sys

def quoteattr(s):
    qs = cgi.escape(s, 1)
    return '"%s"' % (qs,)

from BaseHTTPServer import HTTPServer, BaseHTTPRequestHandler

try:
    import openid
except ImportError:
    print >>sys.stderr, """
Failed to import the OpenID library. In order to use this example, you
must either install the library (see INSTALL in the root of the
distribution) or else add the library to python's import path (the
PYTHONPATH environment variable).

For more information, see the README in the root of the library
distribution or http://www.openidenabled.com/
"""
    sys.exit(1)

from openid.store import filestore
from openid.consumer import consumer
from openid.oidutil import appendArgs
from openid.cryptutil import randomString
from yadis.discover import DiscoveryFailure
from urljr.fetchers import HTTPFetchingError

class OpenIDHTTPServer(HTTPServer):
    """http server that contains a reference to an OpenID consumer and
    knows its base URL.
    """
    def __init__(self, store, *args, **kwargs):
        HTTPServer.__init__(self, *args, **kwargs)
        self.sessions = {}
        self.store = store

        if self.server_port != 80:
            self.base_url = ('http://%s:%s/' %
                             (self.server_name, self.server_port))
        else:
            self.base_url = 'http://%s/' % (self.server_name,)

class OpenIDRequestHandler(BaseHTTPRequestHandler):
    """Request handler that knows how to verify an OpenID identity."""
    SESSION_COOKIE_NAME = 'pyoidconsexsid'

    session = None

    def getConsumer(self):
        return consumer.Consumer(self.getSession(), self.server.store)

    def getSession(self):
        """Return the existing session or a new session"""
        if self.session is not None:
            return self.session

        # Get value of cookie header that was sent
        cookie_str = self.headers.get('Cookie')
        if cookie_str:
            cookie_obj = SimpleCookie(cookie_str)
            sid_morsel = cookie_obj.get(self.SESSION_COOKIE_NAME, None)
            if sid_morsel is not None:
                sid = sid_morsel.value
            else:
                sid = None
        else:
            sid = None

        # If a session id was not set, create a new one
        if sid is None:
            sid = randomString(16, '0123456789abcdef')
            session = None
        else:
            session = self.server.sessions.get(sid)

        # If no session exists for this session ID, create one
        if session is None:
            session = self.server.sessions[sid] = {}

        session['id'] = sid
        self.session = session
        return session

    def setSessionCookie(self):
        sid = self.getSession()['id']
        session_cookie = '%s=%s;' % (self.SESSION_COOKIE_NAME, sid)
        self.send_header('Set-Cookie', session_cookie)

    def do_GET(self):
        """Dispatching logic. There are three paths defined:

          / - Display an empty form asking for an identity URL to
              verify
          /verify - Handle form submission, initiating OpenID verification
          /process - Handle a redirect from an OpenID server

        Any other path gets a 404 response. This function also parses
        the query parameters.

        If an exception occurs in this function, a traceback is
        written to the requesting browser.
        """
        try:
            self.parsed_uri = urlparse.urlparse(self.path)
            self.query = {}
            for k, v in cgi.parse_qsl(self.parsed_uri[4]):
                self.query[k] = v

            path = self.parsed_uri[2]
            if path == '/':
                self.render()
            elif path == '/verify':
                self.doVerify()
            elif path == '/process':
                self.doProcess()
            else:
                self.notFound()

        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            self.send_response(500)
            self.send_header('Content-type', 'text/html')
            self.setSessionCookie()
            self.end_headers()
            self.wfile.write(cgitb.html(sys.exc_info(), context=10))

    def doVerify(self):
        """Process the form submission, initating OpenID verification.
        """

        # First, make sure that the user entered something
        openid_url = self.query.get('openid_identifier')
        if not openid_url:
            self.render('Enter an OpenID Identifier to verify.',
                        css_class='error', form_contents=openid_url)
            return

        oidconsumer = self.getConsumer()
        try:
            request = oidconsumer.begin(openid_url)
        except HTTPFetchingError, exc:
            fetch_error_string = 'Error in discovery: %s' % (
                cgi.escape(str(exc.why)))
            self.render(fetch_error_string,
                        css_class='error',
                        form_contents=openid_url)
        except DiscoveryFailure, exc:
            fetch_error_string = 'Error in discovery: %s' % (
                cgi.escape(str(exc[0])))
            self.render(fetch_error_string,
                        css_class='error',
                        form_contents=openid_url)
        else:
            if request is None:
                msg = 'No OpenID services found for <code>%s</code>' % (
                    cgi.escape(openid_url),)
                self.render(msg, css_class='error', form_contents=openid_url)
            else:
                # Then, ask the library to begin the authorization.
                # Here we find out the identity server that will verify the
                # user's identity, and get a token that allows us to
                # communicate securely with the identity server.

                trust_root = self.server.base_url
                return_to = self.buildURL('process')
                redirect_url = request.redirectURL(trust_root, return_to)

                self.redirect(redirect_url)

    def doProcess(self):
        """Handle the redirect from the OpenID server.
        """
        oidconsumer = self.getConsumer()

        # Ask the library to check the response that the server sent
        # us.  Status is a code indicating the response type. info is
        # either None or a string containing more information about
        # the return type.
        info = oidconsumer.complete(self.query)

        css_class = 'error'
        if info.status == consumer.FAILURE and info.identity_url:
            # In the case of failure, if info is non-None, it is the
            # URL that we were verifying. We include it in the error
            # message to help the user figure out what happened.
            fmt = "Verification of %s failed."
            message = fmt % (cgi.escape(info.identity_url),)
        elif info.status == consumer.SUCCESS:
            # Success means that the transaction completed without
            # error. If info is None, it means that the user cancelled
            # the verification.
            css_class = 'alert'

            # This is a successful verification attempt. If this
            # was a real application, we would do our login,
            # comment posting, etc. here.
            fmt = "You have successfully verified %s as your identity."
            message = fmt % (cgi.escape(info.identity_url),)
            if info.endpoint.canonicalID:
                # You should authorize i-name users by their canonicalID,
                # rather than their more human-friendly identifiers.  That
                # way their account with you is not compromised if their
                # i-name registration expires and is bought by someone else.
                message += ("  This is an i-name, and its persistent ID is %s"
                            % (cgi.escape(info.endpoint.canonicalID),))
        elif info.status == consumer.CANCEL:
            # cancelled
            message = 'Verification cancelled'
        else:
            # Either we don't understand the code or there is no
            # openid_url included with the error. Give a generic
            # failure message. The library should supply debug
            # information in a log.
            message = 'Verification failed.'

        self.render(message, css_class, info.identity_url)

    def buildURL(self, action, **query):
        """Build a URL relative to the server base_url, with the given
        query parameters added."""
        base = urlparse.urljoin(self.server.base_url, action)
        return appendArgs(base, query)

    def redirect(self, redirect_url):
        """Send a redirect response to the given URL to the browser."""
        response = """\
Location: %s
Content-type: text/plain

Redirecting to %s""" % (redirect_url, redirect_url)
        self.send_response(302)
        self.setSessionCookie()
        self.wfile.write(response)

    def notFound(self):
        """Render a page with a 404 return code and a message."""
        fmt = 'The path <q>%s</q> was not understood by this server.'
        msg = fmt % (self.path,)
        openid_url = self.query.get('openid_identifier')
        self.render(msg, 'error', openid_url, status=404)

    def render(self, message=None, css_class='alert', form_contents=None,
               status=200, title="Python OpenID Consumer Example"):
        """Render a page."""
        self.send_response(status)
        self.pageHeader(title)
        if message:
            self.wfile.write("<div class='%s'>" % (css_class,))
            self.wfile.write(message)
            self.wfile.write("</div>")
        self.pageFooter(form_contents)

    def pageHeader(self, title):
        """Render the page header"""
        self.setSessionCookie()
        self.wfile.write('''\
Content-type: text/html

<html>
  <head><title>%s</title></head>
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
  <body>
    <h1>%s</h1>
    <p>
      This example consumer uses the <a href=
      "http://www.openidenabled.com/openid/libraries/python" >Python
      OpenID</a> library. It just verifies that the identifier that you enter
      is your identifier.
    </p>
''' % (title, title))

    def pageFooter(self, form_contents):
        """Render the page footer"""
        if not form_contents:
            form_contents = ''

        self.wfile.write('''\
    <div id="verify-form">
      <form method="get" action=%s>
        Identifier:
        <input type="text" name="openid_identifier" value=%s />
        <input type="submit" value="Verify" />
      </form>
    </div>
  </body>
</html>
''' % (quoteattr(self.buildURL('verify')), quoteattr(form_contents)))

def main(host, port, data_path):
    # Instantiate OpenID consumer store and OpenID consumer.  If you
    # were connecting to a database, you would create the database
    # connection and instantiate an appropriate store here.
    store = filestore.FileOpenIDStore(data_path)

    addr = (host, port)
    server = OpenIDHTTPServer(store, addr, OpenIDRequestHandler)

    print 'Server running at:'
    print server.base_url
    server.serve_forever()

if __name__ == '__main__':
    host = 'localhost'
    data_path = 'cstore'
    port = 8001

    try:
        import optparse
    except ImportError:
        pass # Use defaults (for Python 2.2)
    else:
        parser = optparse.OptionParser('Usage:\n %prog [options]')
        parser.add_option(
            '-d', '--data-path', dest='data_path', default=data_path,
            help='Data directory for storing OpenID consumer state. '
            'Defaults to "%default" in the current directory.')
        parser.add_option(
            '-p', '--port', dest='port', type='int', default=port,
            help='Port on which to listen for HTTP requests. '
            'Defaults to port %default.')
        parser.add_option(
            '-s', '--host', dest='host', default=host,
            help='Host on which to listen for HTTP requests. '
            'Also used for generating URLs. Defaults to %default.')

        options, args = parser.parse_args()
        if args:
            parser.error('Expected no arguments. Got %r' % args)

        host = options.host
        port = options.port
        data_path = options.data_path

    main(host, port, data_path)
