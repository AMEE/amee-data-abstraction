
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
# :title: Class: AMEE::DataAbstraction::Input

module AMEE
  module DataAbstraction
    
    # Subclass of <tt>Term</tt> providing methods and attributes appropriate for
    # representing calculation inputs specifically
    #
    class Input < Term

      # Returns the valid choices for this input
      # (Abstract, implemented only for subclasses of input.)
      def choices
        raise NotImplementedError
      end

      # Returns an ppropriate data structure for a rails select list form helper.
      def options_for_select
        [[nil,nil]]+choices.map{|x|[x.underscore.humanize,x] unless x.nil? }.compact
      end

      # Represents a custom object or pattern to be called via === to determine
      # the whether value set for <tt>self</tt> should be considered acceptable.
      # If validation is specified using a <i>Proc</i> object, the term value 
      # should be initialized as the block variable. E.g.,
      #
      #   my_input.validation 20
      #
      #   my_input.valid?             #=> true
      #
      #   my_input.value 'some string'
      #   my_input.valid?             #=> false
      #
      #   my_input.value 21
      #   my_input.valid?             #=> false
      #
      #   my_input.value 20
      #   my_input.valid?             #=> true
      #
      #   ---
      #
      #   my_input.validation lambda{ |value| value.is_a? Numeric }
      #
      #   my_input.valid?             #=> true
      #
      #   my_input.value 'some string'
      #   my_input.valid?             #=> false
      #
      #   my_input.value 12345
      #   my_input.valid?             #=> true
      #
      #   ---
      #
      #   my_input.validation lambda{ |value| value % 5 == 0 }
      #
      #   my_input.valid?             #=> true
      #
      #   my_input.value 21
      #   my_input.valid?             #=> false
      #
      #   my_input.value 20
      #   my_input.valid?             #=> true
      #
      attr_property :validation

      # Initialization of <i>Input</i> objects follows that of the parent
      # <i>Term</i> class.
      #
      def initialize(options={},&block)
        validation_message {"#{name} is invalid."}
        super
      end

      # Configures the value of <tt>self</tt> to be fixed to <tt>val</tt>, i.e.
      # the value is read-only.
      #
      def fixed val
        @value= val
        @fixed=true
        @optional=false
      end

      # Block to define custom complaint message for an invalid value.
      def validation_message(&block)
        @validation_block=block
      end

      # Set a default validation message appropriate for input terms which have
      # a list of choices.
      def choice_validation_message
        validation_message {"#{name} is invalid because #{value} is not one of #{choices.join(', ')}."}
      end

      # Represents the value of <tt>self</tt>. Set a value by passing an argument.
      # Retrieve a value by calling without an argument, e.g.,
      #
      #  my_term.value 12345
      #
      #  my_term.value                      #=> 12345
      #
      # If <tt>self</tt> is configured to have a fixed value and a value is passed
      # which does not correspond to the fixed value, a <i>FixedValueInterference</i>
      # exception is raised.
      #
      def value(*args)
        unless args.empty?
          if args.first.to_s != @value.to_s
            raise Exceptions::FixedValueInterference if fixed?
            parent.dirty! if parent and parent.is_a? OngoingCalculation
          end
          @value=args.first
        end
        return @value
      end

      # Returns true if <tt>self</tt> is configured to contain a fixed (read-only)
      # value
      #
      def fixed?
        @fixed
      end

      # Returns <tt>true</tt> if the value of <tt>self</tt> does not need to be
      # specified for the parent calculation to calculate a result. Otherwise,
      # returns <tt>false</tt>
      #
      def optional?(usage=nil)
        @optional
      end

      # Returns <tt>true</tt> if the value of <tt>self</tt> is required in order
      # for the parent calculation to calculate a result. Otherwise, returns
      # <tt>false</tt>
      #
      def compulsory?(usage=nil)
        !optional?(usage)
      end

      # Check that the value of <tt>self</tt> is valid. If invalid, and is defined
      # as part of a calculation, add the invalidity message to the parent
      # calculation's error list. Otherwise, raise a <i>ChoiceValidation</i>
      # exception.
      #
      def validate!
        # Typically, you just wipe yourself if supplied value not valid, but
        # deriving classes might want to raise an exception
        #
        invalid unless fixed? || valid?
      end

      # Declare the calculation invalid, reporting to the parent calculation or
      # raising an exception, as appropriate.
      #
      def invalid
        if parent
          parent.invalid(label,instance_eval(&@validation_block))
        else
          raise AMEE::DataAbstraction::Exceptions::ChoiceValidation.new(instance_eval(&@validation_block))
        end
      end

      # Returns <tt>true</tt> if the UI element of <tt>self</tt> is disabled.
      # Otherwise, returns <tt>false</tt>.
      #
      def disabled?
        super || fixed?
      end

      protected

      # Returns <tt>true</tt> if the value set for <tt>self</tt> is either blank
      # or passes custom validation criteria. Otherwise, returns <tt>false</tt>.
      #
      def valid?
        validation.blank? || validation === value
      end

    end
  end
end