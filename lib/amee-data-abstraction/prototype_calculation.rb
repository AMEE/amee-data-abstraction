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
          profile {
            path ivd.path
            choices ivd.choices
          }
        end
      end
      def all_outputs
        amee_return_values.each do |rvd|
          output { path rvd.name}
        end
      end
      def profiles_from_usage(usage)
        self.fixed_usage usage
        amee_ivds.each do |ivd|
          next unless ivd.profile?
          profile {
            path ivd.path
            choices ivd.choices
          } if ivd.compulsory?(usage) || ivd.optional?(usage)
        end
      end
      def terms_from_amee(usage=nil)
        all_drills
        if usage
          profiles_from_usage(usage)
        else
          all_profiles
        end
        all_outputs
      end
      def terms_from_amee_dynamic_usage(ausage)
        all_drills
        usage{ value ausage}
        all_outputs
      end

      def start_and_end_dates
        metadatum {
          path 'start_date'
          interface :date
          validation lambda{|value|
            begin
              Date.parse(value)
              true
            rescue
              false
            end
          }
        }
        metadatum {
          path 'end_date'
          interface :date
          validation lambda{|value|
            begin
              Date.parse(value)
              true
            rescue
              false
            end
          }
        }
      end

      def correcting(label,&block)
        return unless contents[label]
        contents[label].instance_eval(&block)
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
        result.save_amee saved_amee
        result
      end

      private


      def construct(klass,options={},&block)
        new_content=klass.new(options.merge(:parent=>self),&block)
        raise Exceptions::DSL.new(
          "Attempt to create #{klass} without a label") unless new_content.label
        if options[:first]
          @contents.insert_at_start(new_content.label,new_content)
        else
          @contents[new_content.label]=new_content
        end
      end

    end
  end
end