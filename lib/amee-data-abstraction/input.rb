module AMEE
  module DataAbstraction
    class Input < Term
      def choices
        raise NotImplementedError
      end

      def options_for_select
        raise NotImplementedError
      end

      attr_property :validation

      #DSL-----
      def fixed val
        @value= val
        @fixed=true
      end
      #------

      def value(*args)
        unless args.empty?
          raise Exceptions::FixedValueInterference if fixed?&&args.first!=@value
          @value=args.first
        end
        return @value
      end

      def fixed?
        @fixed
      end

      def validate!
        #Typically, you just wipe yourself if supplied value not valid, but
        #deriving classes might want to raise an exception
        value nil unless fixed? || valid?
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