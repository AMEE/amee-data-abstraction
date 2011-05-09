module AMEE
  module DataAbstraction
    class Input < Term
      def choices
        raise NotImplementedError
      end

      def options_for_select
        [[nil,nil]]+choices.map{|x|[x.underscore.humanize,x]}
      end

      attr_property :validation

      #DSL-----
      def fixed val
        @value= val
        @fixed=true
        @optional=false
      end
      #------

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

      def invalid(because=nil)
        if because.blank?
          because="."
        else
          because=" #{because}"
        end
        if parent
          parent.invalid(label,"#{name} is invalid#{because}")
        else
          raise AMEE::DataAbstraction::Exceptions::ChoiceValidation.new("#{name} is invalid#{because}")
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