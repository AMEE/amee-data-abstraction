module AMEE
  module DataAbstraction
    class Metadatum < Input
      def initialize(options={},&block)
        super
        interface :drop_down unless interface
      end
      attr_property :choices
      def compulsory?(usage=nil)
        false
      end
    end
  end
end
