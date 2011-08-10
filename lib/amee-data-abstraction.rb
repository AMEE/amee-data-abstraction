
# Authors::   James Hetherington, James Smith, Andrew Berkeley, George Palmer
# Copyright:: Copyright (c) 2011 AMEE UK Ltd
# License::   Permission is hereby granted, free of charge, to any person obtaining
#             a copy of this software and associated documentation files (the
#             "Software"), to deal in the Software without restriction, including
#             without limitation the rights to use, copy, modify, merge, publish,
#             distribute, sublicense, and/or sell copies of the Software, and to
#             permit persons to whom the Software is furnished to do so, subject
#             to the following conditions:
#
#             The above copyright notice and this permission notice shall be included
#             in all copies or substantial portions of the Software.
#
#             THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#             EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#             MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#             IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#             CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#             TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#             SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'amee'
require 'amee-internal'
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
end