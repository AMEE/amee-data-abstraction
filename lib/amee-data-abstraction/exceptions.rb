
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
#
# :title: Module: AMEE::DataAbstraction::Exceptions

module AMEE
  module DataAbstraction
    module Exceptions
      # Throw this exception when there is a general syntax error in a DSL block.
      class DSL < Exception; end

      # Throw this exception when user specifies a suggested UI for a term which
      # is not supported.
      class InvalidInterface < Exception ; end

      # Throw this exception when user tries to set a value for a term with a
      #read-only value.
      class FixedValueInterference < Exception; end

      # Throw this exception when someone tries to access a term which is not
      # defined for a calculation.
      class NoSuchTerm < Exception; end

      # Throw this exception when trying to create a PI for a calculation which
      # already has a corresponding PI.
      class AlreadyHaveProfileItem < Exception; end

      # Throw this exception when a locally stored calculation and the information
      # on the AMEE server have got out of sync.
      class Syncronization < Exception; end

      # Throw this exception if something went wrong making a profile item.
      class DidNotCreateProfileItem < Exception; end

      # Throw this exception when someone tries to specify a "usage" twice when
      # defining a PrototypeCalculation using the DSL.
      class TwoUsages < Exception; end

      # Throw this exception when an invalid value is set for a term
      class ChoiceValidation < Exception; end

      # Throw this exception when inappropriate units are set for a term.
      class InvalidUnits < Exception; end

    end
  end
end
