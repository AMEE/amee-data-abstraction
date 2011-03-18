require 'amee'
require 'amee-internal'

require File.dirname(__FILE__) + '/core-extensions/class'
require File.dirname(__FILE__) + '/core-extensions/ordered_hash'
require File.dirname(__FILE__) + '/amee-data-abstraction/calculation'
require File.dirname(__FILE__) + '/amee-data-abstraction/ongoing_calculation'
require File.dirname(__FILE__) + '/amee-data-abstraction/prototype_calculation'
require File.dirname(__FILE__) + '/amee-data-abstraction/calculation_set'
require File.dirname(__FILE__) + '/amee-data-abstraction/term'
require File.dirname(__FILE__) + '/amee-data-abstraction/input'
require File.dirname(__FILE__) + '/amee-data-abstraction/drill'
require File.dirname(__FILE__) + '/amee-data-abstraction/profile'
require File.dirname(__FILE__) + '/amee-data-abstraction/output'

module AMEE::DataAbstraction
  mattr_accessor :connection
end