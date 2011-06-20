module AMEE
  module DataAbstraction
    # A collection of Calculations
    class CalculationSet
      # Initialize with a "DSL block", i.e. a block to be evaluated in the
      # context of the instantiated CalculationSet
      def initialize(options={},&block)
        @calculations=ActiveSupport::OrderedHash.new
        @all_blocks=[]
        @all_options={}
        instance_eval(&block) if block
      end

      # Hash of labels to calculations
      attr_accessor :calculations

      # Calculation corresponding to the supplied label
      def [](sym)
        @calculations[sym.to_sym]
      end

      # Instantiate a PrototypeCalculation within this calculation set, initializing with
      # the supplied DSL block to be evaluated in the context of the newly created
      # calculation.
      def calculation(options={},&block)
        new_content=PrototypeCalculation.new(options.merge(@all_options),&block)
        @all_blocks.each {|all_block| new_content.instance_eval(&all_block) }
        new_content.name new_content.label.to_s.humanize unless new_content.name
        @calculations[new_content.label]=new_content
      end

      # Append the supplied block to the DSL block of ALL calculations in this
      # calculation set.
      def all_calculations(options={},&dsl_block)
        @all_blocks.push dsl_block
        @all_options.merge(options)
      end

      # Instantiate several prototype calculations, by loading each possible usage
      # for the category with path given in apath, and then customise each with the
      # supplied DSL block. The usage is given as a parameter to the DSL block.
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