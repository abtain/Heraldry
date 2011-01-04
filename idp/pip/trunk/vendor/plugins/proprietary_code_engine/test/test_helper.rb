require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper') # the default rails helper

# ensure that the Engines testing enhancements are loaded.
require File.join(Engines.config(:root), "engines", "lib", "engines", "testing_extensions")

# Ensure that the code mixing and view loading from the application is disabled
Engines.disable_app_views_loading = true
Engines.disable_app_code_mixing = true

# force these config values
module ProprietaryCodeEngine
#  config :some_option, "some_value"
end

# set up the fixtures location
Test::Unit::TestCase.fixture_path = File.dirname(__FILE__)  + "/../../../../test/fixtures/"
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
