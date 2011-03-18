module AMEE
  module DataAbstraction
    class Input < Term
      def choices
        raise NotImplementedError
      end

      def options_for_select
        raise NotImplementedError
      end


      #DSL-----
      def fixed val
        value val
        @fixed=true
      end
      #------

      def fixed?
        @fixed
      end

      def disabled?
        fixed? || (!set? && !next?)
      end

      def next?
        label==unset_siblings.values.first.label
      end

      protected

      def valid_choice?
        raise NotImplementedError
      end

      def calculation_with_only_earlier
        res=parent.clone
        res.retreat!(self.label)
        return res
      end

    end
  end
end