module AMEE
  module DataAbstraction
    class Profile < Input
      attr_property :choices
      def initialize(options={},&block)
        super
        interface :drop_down unless choices.blank?
        interface :text_box unless interface
      end
      def optional?(usage=nil)
        usage||=parent.current_usage
        usage ? amee_ivd.optional?(usage) : super()
      end

      def compulsory?(usage=nil)
        usage||=parent.current_usage
        usage ? amee_ivd.compulsory?(usage) : super()
      end
      def in_use?(usage)
        compulsory?(usage)||optional?(usage)
      end
      def out_of_use?(usage)
        !in_use?(usage)
      end
      def amee_ivd
        parent.amee_ivds.detect{|x|x.path==path}
      end
      def valid?
        super && (choices.blank? || choices.include?(value))
      end
    end
  end
end
