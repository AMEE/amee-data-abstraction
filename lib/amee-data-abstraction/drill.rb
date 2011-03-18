module AMEE
  module DataAbstraction
    class Drill < Input
      public

      def choices
        c=calculation_with_only_earlier.send(:amee_drill).choices
        c.length==1 ? [value] : c #Intention is to get autodrilled, drill will result in a UID
      end
      
      def valid_choice?
        (choices.include? value) && (choices.length > 1)
      end
      
      def options_for_select
        [nil]+choices
      end

      private

    end
  end
end

