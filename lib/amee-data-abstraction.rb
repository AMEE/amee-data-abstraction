# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

require 'amee'
require 'uuidtools'
require 'quantify'

require File.dirname(__FILE__) + '/core-extensions/class'
require File.dirname(__FILE__) + '/core-extensions/ordered_hash'
require File.dirname(__FILE__) + '/core-extensions/hash'
require File.dirname(__FILE__) + '/core-extensions/proc'
require File.dirname(__FILE__) + '/config/amee_units'
require File.dirname(__FILE__) + '/amee-data-abstraction/exceptions'
require File.dirname(__FILE__) + '/amee-data-abstraction/terms_list'
require File.dirname(__FILE__) + '/amee-data-abstraction/calculation'
require File.dirname(__FILE__) + '/amee-data-abstraction/ongoing_calculation'
require File.dirname(__FILE__) + '/amee-data-abstraction/prototype_calculation'
require File.dirname(__FILE__) + '/amee-data-abstraction/calculation_set'
require File.dirname(__FILE__) + '/amee-data-abstraction/term'
require File.dirname(__FILE__) + '/amee-data-abstraction/input'
require File.dirname(__FILE__) + '/amee-data-abstraction/drill'
require File.dirname(__FILE__) + '/amee-data-abstraction/profile'
require File.dirname(__FILE__) + '/amee-data-abstraction/usage'
require File.dirname(__FILE__) + '/amee-data-abstraction/output'
require File.dirname(__FILE__) + '/amee-data-abstraction/metadatum'

module AMEE::DataAbstraction
  # Connection to AMEE server.
  mattr_accessor :connection
  
  #if defined?(Rails)
  	require File.dirname(__FILE__) + '/amee-data-abstraction/railtie'

    def self.connection
      AMEE::Rails.connection
    end
  #end
end