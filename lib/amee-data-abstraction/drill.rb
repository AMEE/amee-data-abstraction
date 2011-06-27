module AMEE
  module DataAbstraction
    # Input term to a calculation corresponding to an AMEE drill.
    class Drill < Input

      public

      # Should the term be disabled in any UI generated for the calculation?
      # A drill should be disabled in any UI if it is not the next drill,
      # because drill should be chosen in order.
      def disabled?
        super || (!set? && !next?)
      end

      # Initialize with a DSL block
      def initialize(options={},&block)
        interface :drop_down
        super
        choice_validation_message
      end

      private

      # Is the value set for the drill one of the available choices?
      def valid?
        super && (choices.include? value)
      end

      # Get the list of available choices for the drill
      def choices
        c=parent.amee_drill(:before=>label).choices
        c.length==1 ? [value] : c #Intention is to get autodrilled, drill will result in a UID
      end

      # Is this drill the "first unset" drill, i.e. the one which should be set next?
      def next?
        unset? && parent.drills.before(label).all?(&:set?)
      end

    end
  end
end

