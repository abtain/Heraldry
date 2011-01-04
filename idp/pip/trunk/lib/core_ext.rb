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

class Array
  def subset?(other)
    self.each do |x|
      if !(other.include? x)
        return false
      end
    end
    true
  end
  
  def superset?(other)
    other.subset?(self)
  end
end

class Object
  def in?(collection)
    collection.respond_to?(:include?) ? collection.include?(self) : false
  end
end

# Helper methods for Hash, will need to be moved to core_ext.rb
class Hash
  def merge_and_delete!(args, keys_to_remove=[])
    self.merge!(args)
    self.delete_keys!(keys_to_remove)
  end

  def merge_and_delete(args, keys_to_remove=[])
    ret = self.dup
    ret.merge_and_delete!(args, keys_to_remove)
    return ret
  end

  def xmlify
    self.map {|key, value| "<#{key}>#{value}</#{key}>"}.join
  end
        
  protected
    def delete_keys!(keys_to_remove)
      ret = []
      case keys_to_remove
      when Hash
        keys_to_remove.each { |sub_key, value| ret << self[sub_key].delete_keys!(value) }
      when Array
        for key in keys_to_remove
          case key
          when Array
            ret << self.delete_keys!(key)
          when Hash
            key.each { |sub_key, value| ret << self[sub_key].delete_keys!(value) }
          else
            ret << self.delete(key)
          end
        end
      else
        key = keys_to_remove
        ret << self.delete(key)
      end
      return ret
    end
end

