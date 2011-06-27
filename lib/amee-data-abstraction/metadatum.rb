module AMEE
  module DataAbstraction
    #A subclass of input term, corresponding not to any AMEE profile item value or drill.
    class Metadatum < Input

      # Initialise with a DSL block.
      def initialize(options={},&block)
        super
        interface :drop_down unless interface
      end

      # Valid choices for the metadatum. Set in the DSL block.
      attr_property :choices

      # Must the value be set for a calculation to be ready to calculate?
      def compulsory?(usage=nil)
        false
      end

      # Is the chosen value for the term acceptable?
      def valid?
        super && (choices.blank? || choices.include?(value))
      end
    end
  end
end
