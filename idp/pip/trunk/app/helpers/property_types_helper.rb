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

module PropertyTypesHelper
  # If the property_type is owned by the user, allow the user to edit the name.
  # Otherwise, return an uneditable label.
  def label_or_input_for(property_type)
    if property_type.is_not_global_and_is_owned_by?(current_user) 
      text_field_tag "property_title[#{property_type.id}]", property_type.title, :class => 'profile-title', :id => "property_title_#{property_type.id}"
    else 
      "<label for=\"property_type_#{property_type.to_dom_id}\" class=\"profile-title\">#{property_type.title}</label>"
    end 
  end

  def sub_category_label_or_input_for(property_type)
    if property_type.is_not_global_and_is_owned_by?(current_user)
      text_field_tag "category_title[#{property_type.id}]", property_type.title, :class => 'category-title', :id => "category_title#{property_type.id}"
    else
      "<h4 id=\"title_#{property_type.to_dom_id}\" class=\"profile\">#{property_type.title}</h4>"
    end
  end

  def category_label_or_input_for(property_type)
    if property_type.is_not_global_and_is_owned_by?(current_user) 
      text_field_tag( "category_title[#{property_type.id}]", property_type.title, :id => "category_title_#{property_type.to_dom_id}",
                                                                                  :class => "category-title",
                                                                                  :style => "float: left;" ) +
        "\n<script type=\"text/javascript\">\n" +
        "Event.observe('category_title_#{property_type.to_dom_id}', 'click', function(event){ CategoryForm.activate_section('#{property_type.to_dom_id}'); });\n" +
        "</script>"
    else 
      '<h2 class="category" style="float: left;">' + 
        link_to_function( property_type.title, %(CategoryForm.toggle_collapse('#{property_type.to_dom_id}')) ) +
        '</h2>'
    end 
  end

  # Show the delete icon if necessary.  Otherwise, make an empty delete-icon div.
  def delete_icon_if_necessary(property_type, confirm_message)
    if property_type.is_not_global_and_is_owned_by?(current_user)
        link_to_remote( image_tag('buttons/collapse_sm.gif', :size => '16x16', :alt => 'Remove', 
                                                             :id => "delete_icon_#{property_type.to_dom_id}",
                                                             :class => 'delete-icon edit-element', 
                                                             :style => 'margin-top: -3px; display:none'),
                        :url => { :action => 'destroy', :id => property_type.id },
                        :confirm => confirm_message)  
    end 
  end

  def property_delete_icon_if_necessary(property_type)
    delete_icon_if_necessary(property_type, 'Are you sure you want to permanently delete this property?') || "<div class='delete-icon'>&nbsp;</div>" 
  end

  def sub_category_delete_icon_if_necessary(property_type)
    delete_icon_if_necessary(property_type, 'Are you sure you want to permanently delete this sub_category and all its properties?')
  end

  def category_delete_icon_if_necessary(property_type)
    delete_icon_if_necessary(property_type, 'Are you sure you want to permanently delete this category and all its properties?')
  end
  
  def new_subcategory_button(parent)
    link_to_remote( image_tag('buttons/add_subcategory.gif', :size => '105x21', :alt => 'Create new sub category', :class => 'add-sub-category'), 
                    :url => { :action => :create, :type => 'sub_category', :parent => parent } )
  end

  def new_field_button(parent)
    link_to_remote( image_tag('buttons/add_new_field.gif', :size => '107x22', :alt => 'Add a new field', :class => 'add-field', :style => 'margin-top: -2px;'), 
                    :url => { :action => :create, :type => 'property', :parent => parent } )
  end

end
