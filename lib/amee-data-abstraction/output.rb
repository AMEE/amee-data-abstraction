module AMEE
  module DataAbstraction
    class Output < Term
      def visible?
        super && set?
      end
    end
  end
end