require 'cgi'
require 'set'

#
# This module extends ActiveRecord to support automatic escaping of text columns from
# the database.
#
# Note: to use this correctly, you will probably want to remove all the 'h' method calls from your
# ERb templates, or you will end up escaping text twice.  
# You can leave them there if you are the 'belt AND suspenders' type, it won't hurt anything but performance.
#
# some things may start to behave differently when this is installed.  In particular, form fields will be populated with
# the escaped text by default.  This may not be desired behavior.  If this is the case, you can modify your
# action to assign the 'attribute_raw' to the appropriate instance variable and it will work as expected.
# The side benefit of this is that it will be obvious from your code that that particular value contains raw text.
#
# If you define a database column called 'attribute_raw', it will be ignored and not processed any further.
# As a rule, the automatically defined '_raw' attributes will not be saved in the database, nor will it's contents
# affect the escaped attribute unless it is deliberately saved over to the attribute column.
module ActiveRecord
	class Base
		# class variable to save which attributes to filter
    @@attribute_filters= Set.new
    # class variable to save which attributes are ignored
		@@exclude_filters = Set.new
		
    # This method allows specific attributes to be excluded from the automatic escaping process
    # use this if you know that a particular column will never need to be escaped.
    #
    # class model < ActiveRecord::Base
    #   acts_as_raw :column1, :column2
    # end
    #
		def self.acts_as_raw(*user_options)
			if user_options.kind_of? Array
        user_options.map! {|key| "#{self.object_id}_#{key.to_s}"}
				@@exclude_filters = @@exclude_filters + Set.new(user_options)
      else
				raise "Incorrect Parameters.  Use an array of symbols"
			end
		end

    # The auto_escape plugin works by defining an 'after_find' callback from ActiveRecord
    # this callback fires once whenever a record is 'found' and loaded from the database
    # The after_find callback cycles through the internal list of model attributes looking for 
    # any whose database column is a 'text' type, and which has not been excluded by ActiveRecord::Base#acts_as_raw.
    # Once it finds one, it escapes the text (using CGI#escapeHTML) , and saves the unescaped attribute as 
    # '#{attribute}_raw'
    # 
    # Note: defining an after_filter in your model without calling 'super' will bypass this feature entirely
    #
    # Performance for this method could be improved by caching the attributes to be filtered.  Right now it 
    # reconstructs the list for each object, every time it is called
		def after_find
      # find all model attributes
			@@attribute_filters = Set.new(attributes.keys)
      # delete those that don't belong to a 'text' column
			@@attribute_filters = @@attribute_filters.delete_if {|item| column_for_attribute(item) ? !column_for_attribute(item).text? : true}
      # delete if column name contains '_raw'
      @@attribute_filters.reject! {|item| item =~ /_raw/ }
      # give each remaining attribute a unique id so that the exclusion applies only to the correct class and not all subclasses of AR::Base 
			@@attribute_filters.map! {|key| "#{self.class.object_id}_#{key}"}
			@@attribute_filters = @@attribute_filters - @@exclude_filters
			# process the remaining attributes
      @@attribute_filters.each do |key| 
        key =~ /\w+_(\w+)/
				atr = $1
				#define a new attribute with the unescaped version
				self["#{atr}_raw"]=self[atr]
        #escape the text
				self[atr]=CGI.escapeHTML(self[atr]) 
			end
		end 
		 
	end
end

