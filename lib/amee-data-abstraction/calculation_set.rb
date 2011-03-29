module AMEE
  module DataAbstraction
    class CalculationSet
      def initialize(options={},&block)
        @calculations={}
        @all_blocks=[]
        @all_options={}
        instance_eval(&block) if block
      end
      attr_accessor :calculations
      def [](sym)
        @calculations[sym.to_sym]
      end
      def calculation(options={},&block)
        new_content=PrototypeCalculation.new(options.merge(@all_options),&block)
        @all_blocks.each {|all_block| new_content.instance_eval(&all_block) }
        new_content.name new_content.label.to_s.humanize unless new_content.name
        @calculations[new_content.label]=new_content
      end
      def all_calculations(options={},&dsl_block)
        @all_blocks.push dsl_block
        @all_options.merge(options)
      end
      def calculations_all_usages(apath,options={},&dsl_block)
        dummycalc=PrototypeCalculation.new{path apath}
        dummycalc.amee_usages.each do |usage|
          calculation(options){
            path apath
            instance_exec(usage,&dsl_block)
          }
        end
      end
    end
  end
end