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
      def usage(options={},&block)
        all_profiles
        construct(Usage,options.merge(:first=>true),&block)
      end
      def all_drills
        amee_item_definition.drill_downs.each do |apath|
          drill { path apath }
        end
      end
      def all_profiles
        amee_ivds.each do |ivd|
          next unless ivd.profile?
          apath=ivd.path
          profile { path apath}          
        end
      end
      def profiles_from_usage(usage)
        self.fixed_usage usage
        amee_ivds.each do |ivd|
          next unless ivd.profile?
          apath=ivd.path
          profile { path apath } if ivd.compulsory?(usage) || ivd.optional?(usage)
        end
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
        result.fixed_usage fixed_usage
        result
      end

      private


      def construct(klass,options={},&block)
        new_content=klass.new(options.merge(:parent=>self),&block)
        new_content.label new_content.path.underscore.to_sym unless new_content.path.blank?||new_content.label
        raise Exceptions::DSL.new(
          "Attempt to create #{klass} without a label or path") unless new_content.label
        new_content.name label.to_s.humanize unless new_content.name
        if options[:first]
          @contents.insert_at_start(new_content.label,new_content)
        else
          @contents[new_content.label]=new_content
        end
      end

    end
  end
end