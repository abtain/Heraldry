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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include PropertyDisplayMixin

  # Merges two arrays into a hash.
  # ====Parameters
  # keys:: An array of keys for the hash.
  # values:: An array of values for the hash.
  def arrays_to_hash(keys,values)
    hash = {}
    keys.size.times { |i| hash[ keys[i] ] = values[i] }
    hash
  end

  # Returns a string containing the controller name + '/' + controller.action_name
  def controller_action
    @controller_action ||= [controller.controller_name, controller.action_name].join('/')
  end

  # Returns an image link containing the image in images/buttons/help.gif
  def render_help(title, id=nil, options = {})
    link_to(image_tag('buttons/help.gif', :size => '22x22'), '#', {:class => "tooltip question-mark", :title => title, :id => "icon-#{id}"}.merge(options))
  end

  # returns 'selected' for the navigation menu if the controller/action_name matches
  #
  #   selected?(/^account/) # matches account/
  def selected?(pattern)
    'selected' if controller_action =~ pattern
  end

  # Returns a div containing the error messages for _object_name_.
  # ====Parameters
  # object_name:: A string that is the name of the object we're reporting errors for.
  # options:: A hash containing options for the messages.
  #   header_tag:: A valid html header tag (h1, h2, h3, ...)
  #   id::         An id for the unordered list element.
  #   class::      A class for the unordered list element.
  def error_messages_for(object_name, options = {})
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}")
    if object && !object.errors.empty?
      content = content_tag("div",
        content_tag(
          options[:header_tag] || "h2",
          "#{pluralize(object.errors.count, "error")} prohibited this #{object_name.to_s.gsub("_", " ")} from being saved"
        ) +
        content_tag("p", "There were problems with the following fields:") +
        content_tag("ul", object.errors.full_messages.collect { |msg| content_tag("li", msg) }),
        "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
      )
      render :partial => "layouts/errors", :locals => {:content => content}
    else
      ""
    end
  end

  # Renders an image tag for the current User's Avatar.
  def current_avatar
    logged_in? ? 
      image_tag("/avatar/show?secret_code=#{session[:secret_code]}&", :alt => current_user.login) :  # The '&' is a hack to prevent the appended .png from spoiling the call
      image_tag('id_image.gif', :alt => "ID Image", :size => '70x70')
  end
  
  # Renders a link to _action_ to sort an object by _title_ in the order specified by _sort_method_.
  # ====Parameters
  # title:: The title for the link *and* the property to sort by.
  # sort_method::'asc' or 'desc'.  Specifies the sort order.
  # action:: Defaults to :list.  Override to specify a different action to link to.
  def sort_link_for(title, sort_method, action=:list)
    link_to title, {:action => action, :order_by => sort_method, :order => (@order_by == sort_method) ? 'desc' : 'asc'},
                   {:class => 'tooltip', :title => "Sort By #{title}", :id => "header-#{title.downcase.gsub(' ', '-')}"}
  end

  def row_class(counter)
    counter % 2 == 0 ? :even : :odd
  end

  def show_flash?(flash)
    f = flash.select { |key, val| show_flash_key?(key) }
    f.empty?
  end

  def show_flash_key?(key)
    [:error, :notice].include?(key)
  end

  def render_children(parent)
    rendered_children = ""
    parent.children.each_with_index do |leaf,index| 
      if leaf.is_global_or_owned_by?(current_user) && leaf.has_children?
        rendered_children << render(:partial => "sub_category", :object => leaf)
      elsif current_user.properties.has_property?(leaf)
        rendered_children << render(:partial => "property", :object => current_user.properties.find_by_property_type(leaf), 
                                    :locals => { :render_newfield => ( index.zero? && !parent.is_not_global_and_is_owned_by?(current_user) ), :parent => parent} )
      end 
    end
    return rendered_children
  end
  
  ###### METHODS FOR layouts/_header.rhtml ############################  
  def render_specific_header_items
    if !on_cached_page? && has_access?(current_user) 
      render(:partial => '/layouts/logged_in_header_items', :locals => {:current_user => current_user})
    else
      (on_login_page? || on_cached_page? ? '' : render(:partial => '/layouts/login_button')) + 
      render(:partial => '/layouts/regular_header_items')
    end 
  end
  
  def on_cached_page?
    controller_action =~ /^static/
  end
  
  def on_login_page?
    controller_action =~ /^account\/login/
  end
  
  def login_page_url
  	if APP_CONFIG[:ssl_disabled]
	  	return "http://#{APP_CONFIG[:app_host]}/account/login"
	else
	  	return "https://#{APP_CONFIG[:app_host]}/account/login"
	end
  end
end
