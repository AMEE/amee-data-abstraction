module AMEE
  module DataAbstraction
    class Input < Term

      def choices
        raise NotImplementedError
      end

      def options_for_select
        [[nil,nil]]+choices.map{|x|[x.underscore.humanize,x] unless x.nil? }.compact
      end

      attr_property :validation

      def initialize(options={},&block)
        validation_message {"#{name} is invalid."}
        super
      end

      #DSL-----
      def fixed val
        @value= val
        @fixed=true
        @optional=false
      end
      #------

      def validation_message(&block)
        @validation_block=block
      end

      def choice_validation_message #Need to make this into a block, for lazy evaluation
        validation_message {"#{name} is invalid because #{value} is not one of #{choices.join(', ')}."}
      end

      def value(*args)
        unless args.empty?
          if args.first!=@value
            raise Exceptions::FixedValueInterference if fixed?
            parent.dirty! if parent
          end
          @value=args.first
        end
        return @value
      end

      def fixed?
        @fixed
      end

      def optional?(usage=nil)
        @optional
      end

      def compulsory?(usage=nil)
        !optional?(usage)
      end

      def validate!
        #Typically, you just wipe yourself if supplied value not valid, but
        #deriving classes might want to raise an exception
        invalid unless fixed? || valid?
      end

      

      def invalid
        if parent
          parent.invalid(label,instance_eval(&@validation_block))
        else
          raise AMEE::DataAbstraction::Exceptions::ChoiceValidation.new(instance_eval(&@validation_block))
        end
      end

      def disabled?
        super || fixed?
      end

      protected

      def valid?
        validation.blank? || validation === value
      end

    end
  end
end