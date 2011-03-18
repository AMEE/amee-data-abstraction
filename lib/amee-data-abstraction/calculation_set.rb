module AMEE
  module DataAbstraction
    class CalculationSet
      def initialize(options={},&block)
        @calculations={}
        instance_eval(&block) if block
      end
      attr_accessor :calculations
      def [](sym)
        @calculations[sym.to_sym]
      end
      def calculation(options={},&block)
        new_content=PrototypeCalculation.new(options,&block)
        @calculations[new_content.label]=new_content
      end
    end
  end
end