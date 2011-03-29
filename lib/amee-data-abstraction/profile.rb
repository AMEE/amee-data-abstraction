module AMEE
  module DataAbstraction
    class Profile < Input
      def initialize(options={},&block)
        super
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
    end
  end
end
