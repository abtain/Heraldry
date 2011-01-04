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

module PropertyDisplayMixin

  # Create an input tag of the appropriate type for the given _property_.
  # ====Parameters
  # property:: The Property for which we are creating the input tag. It's PropertyType#control_type
  #            and PropertyType#format determine what type of input will be used.
  #            PropertyType#control_type == 'input_text' specifies a text box.
  #            PropertyType#control_type == 'date_select' specifies a select date.
  #            PropertyType#control_type == 'select' indicates a select box with the options specified by
  #                                                  PropertyType#format
  #            Available options for PropertyType#format are 'gender', 'langauge', 'country', and 'time_zone'
  def input_for_property(property)
    control_type = property.property_type.control_type
    format = property.property_type.format
    self.send("input_for_control_type_#{control_type}", property, format)
  end

  # Returns a user friendly version Property.value for display.
  # ====Parameters
  # property:: The Property to be formatted.
  def friendly_property_value(property)
    @@openid_map ||= current_user.properties.openid
    return '' unless property.value && property.value != ''
    
    case property.property_type.short_name
    when @@openid_map['dob']
      property.value.to_time.strftime("%B %d, %Y")
    when @@openid_map['timezone']
      property.value.gsub(/\//, ' - ').gsub(/_/, ' ')
    when @@openid_map['language']
      language = Globalize::Language.find_by_iso_639_2(property.value)
      format_language(language)
    when @@openid_map['country']
      begin
        TZInfo::Country.get(property.value).name
      rescue
        property.value
      end
    else
      property.value
    end
  end
  
private
  def input_for_control_type_input_text(property, format)
    return "<input class='profile-field' id='property_#{property.id}' name='property[#{property.id}]'" + 
           " type='text' value='#{property.value}' />"
  end

  def input_for_control_type_date_select(property, format)
    options = {:prefix => "property[#{property.id}]", :include_blank => true,
               :start_year => 1930, :end_year => Date.today.year}
    return '<div class="profile-field">' +
           select_month(property.value, options) + 
           select_day(property.value, options) + 
           select_year(property.value, options) +
           '</div>'
  end

  def input_for_control_type_select(property, format)
    return select_tag("property[#{property.id}]",
                      add_blank_option(self.send("#{format}_options_for_select".to_sym, property.value)),
                      :class => 'profile-field')
  end

  # Adds a blank option to a group of select options. If no options are selected,
  # then the blank option is marked as selected.
  # ====Parameters
  # options:: A string containing the options to which we are adding the blank option.
  def add_blank_option(options)
    selected = (options =~ /selected=/ ? '' : ' selected="selected"')
    options =~ /value=""/ ? options : ("<option value=\"\"#{selected}></option>" + options)  
  end

  # Mark the _selected_ option as selected.
  # ====Parameters
  # options:: A string of options for a select statment.
  # selected:: The value tag for the option that is to be selected.
  def select_option(options, selected)
    selected_string = ' selected="selected"'
    if options =~ /value="#{selected}"/
      return $` + $& + selected_string + $'
    else
      return options
    end
  end

  # Returns select options for Male and Female.
  # ====Parameters
  # selected:: Specify an option to be selected. Accepted values are 'Male' and 'Female'
  def gender_options_for_select(selected = nil)
    return select_option(GENDER_OPTIONS_FOR_SELECT, selected)
  end
  
  # Returns select options for a group of languages specified by the Globalize::Language class.
  # ====Parameters
  # selected:: Specify an option to be selected. Accepted values are the iso_639_2 values for
  #            the language as specified in Globalize::Language
  def language_options_for_select(selected = nil)
    return select_option(LANGUAGE_OPTIONS_FOR_SELECT, selected)
  end
  
  # Displays a Globalize::Language in a user friendly format.
  # ====Parameters
  # language:: The Globalize::Language to be formatted.
  def format_language(language)
    return '' unless language
    return language.to_s + 
           (language.english_name_locale ? " - #{language.english_name_locale}" : '') + 
           (language.english_name_modifier ? " - #{language.english_name_modifier}" : '')
  end

  # Returns select options for the countries in TZInfo::Country.
  # ====Parameters
  # selected:: Specify a country to be selected using its country code specified
  #            in TZInfo::Country.
  def country_options_for_select(selected = nil)
    return select_option(COUNTRY_OPTIONS_FOR_SELECT, selected)
  end
  
  # Returns select options for TimeZones using the tz_database wrapped by TZInfo::Timezone
  # ====Parameters
  # select:: Specify a value using the identifier for the timezone used by TZInfo::Timezone
  def time_zone_options_for_select(selected = nil)
    return select_option(TIME_ZONE_OPTIONS_FOR_SELECT, selected)
  end
 
end
