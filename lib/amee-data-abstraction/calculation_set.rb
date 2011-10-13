# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: AMEE::DataAbstraction::CalculationSet

module AMEE
  module DataAbstraction
    
    # The <i>CalculationSet</i> class represents a collection of prototype
    # calculations (of the class <i>ProtptypeCalculation</i>.
    #
    # Prototype calculations are contained within the @calculations instance variable
    # ordered hash. Calculations can be added manually to the @calculations hash or
    # initialized in place using the <tt>#calculation</tt> method which takes an
    # options hash or block for specifying the prototype calculation properties.
    #
    # Typical usage is to initialize the <i>CalculationSet</i> and its daughter
    # prototype calculations together using block syntax, thus:
    #
    #   Calculations = CalculationSet.new {
    #
    #     calculation {
    #       label :electricity
    #       path "/some/path/for/electricity"
    #       ...
    #     }
    #
    #     calculation {
    #       label :transport
    #       path "a/transport/path"
    #       ...
    #     }
    #
    #     ...
    #   }
    #
    class CalculationSet

      # Initialize a <i>CalculationSet</i> with a "DSL" block, i.e. a block to be
      # evaluated in the context of the instantiated CalculationSet
      #
      def initialize(options={},&block)
        @calculations=ActiveSupport::OrderedHash.new
        @all_blocks=[]
        @all_options={}
        instance_eval(&block) if block
      end

      # Collection methods

      @@sets = {}
      
      def self.find(name)
        @@sets[name] ||= load_set(name)
      end
      
      private
      
      def self.load_set(name)
        CalculationSet.new {
          instance_eval(File.open("#{::Rails.root}/config/calculations/#{name.to_s}.rb").read)
        }
      end
      
      public

      # Access the @calculations instance variable ordered hash. Keys are labels
      # assocaited with each prototype calculation; values are the instantiated
      # <i>PrototypeCalculation</i> objects
      #
      attr_accessor :calculations

      # Shorthand method for returning the prototype calculation which is represented
      # by a label matching <tt>sym</tt>
      #
      def [](sym)
        @calculations[sym.to_sym]
      end

      # Instantiate a <i>PrototypeCalculation</i> within this calculation set,
      # initializing with the supplied DSL block to be evaluated in the context
      # of the newly created calculation
      #
      def calculation(options={},&block)
        new_content=PrototypeCalculation.new(options.merge(@all_options),&block)
        @all_blocks.each {|all_block| new_content.instance_eval(&all_block) }
        new_content.name new_content.label.to_s.humanize unless new_content.name
        @calculations[new_content.label]=new_content
      end

      # Append the supplied block to the DSL block of ALL calculations in this
      # calculation set. This is useful for configuration which is required
      # across all calculations (e.g. overriding human readable names or adding
      # globally applicable metadatum)
      #
      def all_calculations(options={},&dsl_block)
        @all_blocks.push dsl_block
        @all_options.merge(options)
      end

      # Instantiate several prototype calculations, by loading each possible usage
      # for the category with path given in <tt>apath</tt>.
      # 
      # Each instantiated calculation is customised on the basis of the supplied
      # DSL block. The usage is given as a parameter to the DSL block
      #
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