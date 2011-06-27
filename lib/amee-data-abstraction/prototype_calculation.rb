module AMEE
  module DataAbstraction
    # Class defining a type of calculation available to the app.
    class PrototypeCalculation < Calculation

      public

      #Initialize by specifying a block to be evaluated in the context of the
      #new instance, to set category path, terms to use...
      def initialize(options={},&block)
        super()
        instance_eval(&block) if block
      end


      # Add a profile item input term to the calculation, and then evaluate the
      # given block in its context, to initialize it.
      def profile(options={},&block)
        construct(Profile,options,&block)
      end

      # Add a drill input term to the calculation, and then evaluate the
      # given block in its context, to initialize it.
      def drill(options={},&block)
        construct(Drill,options,&block)
      end

      # Add an output term to the calculation, and then evaluate the
      # given block in its context, to initialize it.
      def output(options={},&block)
        construct(Output,options,&block)
      end

      # Add a metadatum input term to the calculation, and then evaluate the
      # given block in its context, to initialize it.
      def metadatum(options={},&block)
        construct(Metadatum,options,&block)
      end

      # Automatically set up all profile item value input terms, together with a usage corresponding to a particular usage definition
      # define the Usage term by evaluating the supplied block in the context of a new usage term instance.
      # When the usage term value is changed, the profile item value terms will be activated and inactivated as appropriate. 
      def usage(options={},&block)
        all_profiles
        construct(Usage,options.merge(:first=>true),&block)
      end

      #Automatically look up in AMEE all drills corresponding to the category path,
      #and define drill terms.
      def all_drills
        # Need to use #drill_downs rather than simply finding drills
        # directly from #amee_ivds in order to establish drill order
        amee_item_definition.drill_downs.each do |apath|
          amee_ivds.each do |ivd|
            next unless ivd.path == apath
            drill {
              path ivd.path
              name ivd.name
            }
          end
        end
      end

      #Automatically look up in AMEE all profile item values for the category
      #and define Profile Terms for them.
      def all_profiles
        amee_ivds.each do |ivd|
          next unless ivd.profile?
          profile {
            path ivd.path
            name ivd.name
            choices ivd.choices
            default_unit ivd.unit
            default_per_unit ivd.perunit
          }
        end
      end

      #Automatically look up in AMEE all return value definitions for the category
      #and define Output terms for them.
      def all_outputs
        amee_return_values.each do |rvd|
          output {
            path rvd.name
            default_unit rvd.unit
            default_per_unit rvd.perunit
          }
        end
      end

      #Automatically define all profile terms statically corresponding to the
      #specified usage. This is a one-time-only choice, the corresponding usage
      #will be defined at application startup. Use PrototypeCalculation#usage for a
      #runtime-adjustable usage.
      def profiles_from_usage(usage)
        self.fixed_usage usage
        amee_ivds.each do |ivd|
          next unless ivd.profile?
          profile {
            path ivd.path
            name ivd.name
            choices ivd.choices
            default_unit ivd.unit
            default_per_unit ivd.perunit
          } if ivd.compulsory?(usage) || ivd.optional?(usage)
        end
      end

      # Automatically define all drills, profile item value terms, and return values for the corresponding
      # category in AMEE. Optionally, load only those profile terms corresponding to the supplied usage.
      def terms_from_amee(usage=nil)
        all_drills
        if usage
          profiles_from_usage(usage)
        else
          all_profiles
        end
        all_outputs
      end

      #Automatically define all drills, profile item value terms, and return values for the corresponding
      #category in AMEE. Also define a usage term for the specified usage, which automatically activates and
      #inactivates profile terms as its value is adjusted.
      def terms_from_amee_dynamic_usage(ausage)
        all_drills
        usage{ value ausage}
        all_outputs
      end

      # Define metadata terms appropriate for storing start and end dates for an AMEE profile item.
      def start_and_end_dates
        metadatum {
          path 'start_date'
          name 'Start date'
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
          name 'End date'
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

      # Reopen and modify the definition of the term with the given label, by
      # evaluating the given block in its context. Use this to tweak terms autoloaded from AMEE.
      def correcting(label,&block)
        return unless contents[label]
        contents[label].instance_eval(&block)
      end

      #Instantiate an OngoingCalculation based on this prototype, ready for
      #communication with AMEE.
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

      # Construct a term of class klass, and evaluate a DSL block in its context.
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