module AMEE
  module DataAbstraction
    # Subclass of Term relating to inputs to calculations
    class Input < Term

      # Valid choices for this input
      # (Abstract, implemented only for subclasses of input.)
      def choices
        raise NotImplementedError
      end

      # Appropriate data structure for a rails form helper to make a dropdown.
      def options_for_select
        [[nil,nil]]+choices.map{|x|[x.underscore.humanize,x] unless x.nil? }.compact
      end

      # Object or pattern to be called via === to determine whether value set for the
      # term is acceptable.
      attr_property :validation

      def initialize(options={},&block)
        validation_message {"#{name} is invalid."}
        super
      end

      #Specify, in the DSL, that the value for the term, val, is read-only.
      def fixed val
        @value= val
        @fixed=true
        @optional=false
      end

      #Block to evaluate to generate complaint message for an invalid value.
      def validation_message(&block)
        @validation_block=block
      end

      # Set a default validation message appropriate for input terms which have
      # a list of choices.
      def choice_validation_message
        validation_message {"#{name} is invalid because #{value} is not one of #{choices.join(', ')}."}
      end

      # Set or access the value of the term.
      # Call like an attr_parameter, i.e.
      # set with mycalc.value 5, get with mycalc.value
      def value(*args)
        unless args.empty?
          if args.first.to_s!=@value.to_s
            raise Exceptions::FixedValueInterference if fixed?
            parent.dirty! if parent and parent.is_a? OngoingCalculation
          end
          @value=args.first
        end
        return @value
      end

      #Is the value read-only?
      def fixed?
        @fixed
      end

      # Must the value be specified for the calculation to give a result?
      def optional?(usage=nil)
        @optional
      end

      # May the value be left unspecified for the calculation to give a result?
      def compulsory?(usage=nil)
        !optional?(usage)
      end

      #Check that the term's value is valid. If invalid, and is defined as part of a calculation,
      #add the invalidity message to the calculation's errors list, otherwise, raise a ChoiceValidation exception.
      def validate!
        #Typically, you just wipe yourself if supplied value not valid, but
        #deriving classes might want to raise an exception
        invalid unless fixed? || valid?
      end

      # Declare the calculation invalid, reporting to the parent calculation or raising an exception, as appropriate.
      def invalid
        if parent
          parent.invalid(label,instance_eval(&@validation_block))
        else
          raise AMEE::DataAbstraction::Exceptions::ChoiceValidation.new(instance_eval(&@validation_block))
        end
      end

      # Should the term's UI element be disabled in a generated UI?
      def disabled?
        super || fixed?
      end

      protected

      # Is the term's value valid?
      def valid?
        validation.blank? || validation === value
      end

    end
  end
end