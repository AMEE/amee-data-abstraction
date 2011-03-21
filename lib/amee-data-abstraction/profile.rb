module AMEE
  module DataAbstraction
    class Profile < Input
      def initialize(options={},&block)
        super
        interface :text_box unless interface
      end
    end
  end
end
