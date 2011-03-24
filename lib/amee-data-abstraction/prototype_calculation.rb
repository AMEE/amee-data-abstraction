module AMEE
  module DataAbstraction
    class PrototypeCalculation < Calculation

      public

      def initialize(options={},&block)
        super()
        instance_eval(&block) if block
      end

      #DSL-----------------

      def profile(options={},&block)
        construct(Profile,options,&block)
      end
      def drill(options={},&block)
        construct(Drill,options,&block)
      end
      def output(options={},&block)
        construct(Output,options,&block)
      end
      def metadatum(options={},&block)
        construct(Metadatum,options,&block)
      end

      #--------------------

      def begin_calculation
        result=OngoingCalculation.new
        contents.each do |k,v|
          result.contents[k]=v.clone
          result.contents[k].parent=result
        end
        result.path path
        result.name name
        result.label label
        result
      end

      private


      def construct(klass,options={},&block)
        new_content=klass.new(options.merge(:parent=>self),&block)
        raise Exceptions::DSL.new(
          "Attempt to create #{klass} without a label") unless new_content.label
        @contents[new_content.label]=new_content
      end

    end
  end
end