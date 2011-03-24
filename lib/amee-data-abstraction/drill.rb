module AMEE
  module DataAbstraction
    class Drill < Input
      public

      def disabled?
        super || (!set? && !next?)
      end

      def initialize(options={},&block)
        interface :drop_down
        super
      end

      private

      def valid?
        super && (choices.include? value) && (choices.length > 1)
      end
      
      def choices
        c=parent.amee_drill(:before=>label).choices
        c.length==1 ? [value] : c #Intention is to get autodrilled, drill will result in a UID
      end

      def next?
        unset? && parent.drills.before(label).all?(&:set?)
      end

    end
  end
end

