module AMEE
  module DataAbstraction
    class Drill < Input
      public

      def options_for_select
        [nil]+choices
      end

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
        raise Exceptions::EntryOrderException unless \
          parent.before(label,Drill).values.all?{|x|x.set?}
        c=with_only_earlier(:amee_drill).choices
        c.length==1 ? [value] : c #Intention is to get autodrilled, drill will result in a UID
      end

    end
  end
end

