# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module SslRequirement
  def self.included(controller)
    controller.extend(ClassMethods)
  end

  module ClassMethods
    # Specifies that the named actions requires an SSL connection to be performed (which is enforced by ensure_proper_protocol).
    def ssl_required(actions = {})
      self.before_filter :ssl_required, actions
    end
    
    def ssl_prohibited(actions = {})
      self.before_filter :ssl_prohibited, actions
    end
  end
  
  protected
    # Returns true if the current action is supposed to run as SSL
=begin
    def ssl_required?
      (self.class.read_inheritable_attribute(:ssl_required_actions) || []).include?(action_name.to_sym)
    end
    
    def ssl_allowed?
      (self.class.read_inheritable_attribute(:ssl_allowed_actions) || []).include?(action_name.to_sym)
    end
=end

  private
    def ssl_required
      unless request.ssl?
        redirect_to "https://" + request.host + request.request_uri + (request.env['QUERY_STRING'] ? '?' + request.env['QUERY_STRING'] : '')
        return false
      end        
    end
    
    def ssl_prohibited
      if request.ssl?
        redirect_to "http://" + request.host + request.request_uri + (request.env['QUERY_STRING'] ? '?' + request.env['QUERY_STRING'] : '')
        return false
      end
    end
=begin  
    def ensure_proper_protocol
      return true if ssl_allowed?

      if ssl_required? && !request.ssl?
        redirect_to "https://" + request.host + request.request_uri
        return false
      elsif request.ssl? && !ssl_required?
        redirect_to "http://" + request.host + request.request_uri
        return false
      end
    end
=end
end