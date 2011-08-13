# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

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
