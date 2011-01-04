# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module RorSpider
  def check_generated_page( next_link ); end

  def check_static_page( next_link ); end

  def consume_page( html, url )
    body = HTML::Document.new html
    body.find_all(:tag=>'a').each do |tag|
      # find all the ajax links
      if tag.attributes['onclick'] =~ /^new Ajax.Updater\(['"].*?['"], ['"](.*?)['"]/i
        queue_link( $1, url )
      else
        # find all the normal links
        queue_link( tag.attributes['href'], url )
      end
    end
    register_form_page( url ) unless body.find_all( :tag => 'form' ).empty?
  end
  
  def get_and_check( next_link )
    if next_link.uri =~ %r{\.html$}
      @response.body = File.open("#{RAILS_ROOT}/public/#{next_link.uri}").read
      check_static_page next_link
    else
      get next_link.uri
      check_generated_page next_link
    end
  end
  
  def register_form_page( url ); end

  def setup_ror_spider
    @orig_stderr = $stderr
    $stderr = StringIO.new
  end

  def spider( uri )
    @links_to_visit = []
    @visited_uris = {}
    @visited_uris[uri] = true
    consume_page( @response.body, uri )
    until @links_to_visit.empty?
      next_link = @links_to_visit.shift
      unless @visited_uris[next_link.uri]
        get_and_check next_link
        consume_page( @response.body, next_link.uri )
        @visited_uris[next_link.uri] = true
      end
    end
  end
  
  def teardown_ror_spider
    $stderr = @orig_stderr
  end
  
  def queue_link( dest, source )
    unless dest =~ %r{^(http://|mailto:|#)}
      @links_to_visit << Link.new( dest, source )
    end
  end
  
  Link = Struct.new( :uri, :source )
end

