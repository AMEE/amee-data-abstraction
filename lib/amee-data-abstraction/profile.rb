module AMEE
  module DataAbstraction
    # Term subclass for AMEE profile item values.
    class Profile < Input
      #Property defining list of acceptable choices for the item - nil for unrestricted.
      attr_property :choices

      # Initialise the item with a DSL block.
      def initialize(options={},&block)
        super
        interface :drop_down unless choices.blank?
        choice_validation_message unless choices.blank?
        interface :text_box unless interface
      end

      # Does the item not have to be given before a calculation can be calculated?
      # Load from an AMEE usage definition if available.
      def optional?(usage=nil)
        usage||=parent.current_usage
        usage ? amee_ivd.optional?(usage) : super()
      end

      # Does the item have to be given before a calculation can be calculated?
      # Load from an AMEE usage definition if available.
      def compulsory?(usage=nil)
        usage||=parent.current_usage
        usage ? amee_ivd.compulsory?(usage) : super()
      end

      # Is the item not forbidden from the current AMEE usage definition?
      def in_use?(usage)
        compulsory?(usage)||optional?(usage)
      end

      # Is the item not forbidden from the current AMEE usage definition?
      def out_of_use?(usage)
        !in_use?(usage)
      end

      # The AMEE item-value-definition corresponding to the term.
      def amee_ivd
        parent.amee_ivds.detect{|x|x.path==path}
      end

      #Is the current value a valid one? (Checks choices if defined, otherwise,
      #uses arbitrary pattern from DSL block...)
      def valid?
        super && (choices.blank? || choices.include?(value))
      end
    end
  end
end
