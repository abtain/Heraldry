#  Copyright (c) 2006 Trotter Cashion <trotter@eastmedia.com>


module ProprietaryCodeEngine
  module VERSION
    Major = 0 # change implies compatibility breaking with previous versions
    Minor = 1 # change implies backwards-compatible change to API
    Release = 0 # incremented with bug-fixes, updates, etc.
  end
end

Engines.current.version = ProprietaryCodeEngine::VERSION

# load up all the required files we need...
require 'proprietary_code_engine'

