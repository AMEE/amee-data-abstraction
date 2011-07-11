
# Authors::   James Hetherington, James Smith, Andrew Berkeley, George Palmer
# Copyright:: Copyright (c) 2011 AMEE UK Ltd
# License::   Permission is hereby granted, free of charge, to any person obtaining
#             a copy of this software and associated documentation files (the
#             "Software"), to deal in the Software without restriction, including
#             without limitation the rights to use, copy, modify, merge, publish,
#             distribute, sublicense, and/or sell copies of the Software, and to
#             permit persons to whom the Software is furnished to do so, subject
#             to the following conditions:
#
#             The above copyright notice and this permission notice shall be included
#             in all copies or substantial portions of the Software.
#
#             THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#             EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#             MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#             IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#             CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#             TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#             SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# :title: Class: AMEE::DataAbstraction::PrototypeCalculation

module AMEE
  module DataAbstraction

    # The <i>PrototypeCalculation</i> class represents a template for a potential
    # calculation within the AMEE platfom.
    # 
    # The class inherits from the <i>Calculation</i> class and is therefore primarly
    # characterised by the <tt>label</tt>, <tt>name</tt>, and <tt>path</tt> attributes,
    # as well as an associated instance of the <tt>TermsList</tt> class which represents
    # each of the values (input, outputs, metdata) involved in the calculation. Unlike
    # the <i>OngoingCalculation</i>, the terms associated with an instance of
    # <i>PrototypeCalculation</i> will typically contains blank (nil) values.
    #
    # Objects of the class <i>PrototypeCalculation</tt> are typically instantiated
    # using block ('DSL') syntax, within which each of the attributes and associated
    # terms are defined. Thus,
    #
    #   calculation = PrototypeCalculation.new {
    #
    #     label :electricity
    #     name "Domestic electricity consumption"
    #     path "some/path/in/amee"
    #     drill { ... }
    #     profile { ... }
    #     ...
    #
    #   }
    #
    class PrototypeCalculation < Calculation

      public

      # Initialize a new instance of <i>PrototypeCalculation</i>.
      # 
      # The calculation can be configured in place by passing a block (evaluated
      # in the context of the new instance) which defines the calculation properties
      # using the macro-style instance helper methods.
      #      
      #   calculation = PrototypeCalculation.new {
      #   
      #     label :transport
      #     path "some/other/path/in/amee"
      #     terms_from_amee
      #     metadatum { ... }
      #     start_and_end_dates
      #     ...
      #     
      #   }
      #
      def initialize(options={},&block)
        super()
        instance_eval(&block) if block
      end

      # Associate a new instance of the <i>Profile</i> class (subclass of the 
      # <i>Term</i> class) with <tt>self</tt>, for representing an AMEE profile item input
      # 
      # The newly instantiated <i>Term</i> object is configured according to the
      # ('DSL') block passed in.
      #
      #   my_protptype.profile {
      #     label :energy_used
      #     path 'energyUsed'
      #     default_unit :kWh
      #   }
      #
      def profile(options={},&block)
        construct(Profile,options,&block)
      end

      # Associate a new instance of the <i>Drill</i> class (subclass of the
      # <i>Term</i> class) with <tt>self</tt>, for representing an AMEE drill down choice
      #
      # The newly instantiated <i>Term</i> object is configured according to the
      # ('DSL') block passed in.
      #
      #   my_protptype.drill {
      #     label :fuel_type
      #     path 'fuelType'
      #     fixed 'diesel'
      #   }
      #
      def drill(options={},&block)
        construct(Drill,options,&block)
      end

      # Associate a new instance of the <i>Output</i> class (subclass of the
      # <i>Term</i> class) with <tt>self</tt>, for representing an AMEE return value
      #
      # The newly instantiated <i>Term</i> object is configured according to the
      # ('DSL') block passed in.
      #
      #   my_protptype.output {
      #     label :co2
      #     path 'CO2'
      #   }
      #
      def output(options={},&block)
        construct(Output,options,&block)
      end

      # Associate a new instance of the <i>Metadatum</i> class (subclass of the
      # <i>Term</i> class) with <tt>self</tt>, for representing arbitrary metadata which
      # is to be associated with each calculation. These may represent unique
      # references to location, equipment (vehicles, furnaces), reporting periods,
      # for example.
      #
      # The newly instantiated <i>Term</i> object is configured according to the
      # ('DSL') block passed in.
      #
      #   my_protptype.metadatum {
      #     label :reporting_period
      #     value "July 2010"
      #   }
      #
      def metadatum(options={},&block)
        construct(Metadatum,options,&block)
      end

      # Helper method for automatically instantiating <i>Drill</i> class term
      # objects representing all drill down choices based on those associated with
      # the AMEE platform category with which <tt>self</tt> corresponds.
      #
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

      # Helper method for automatically instantiating <i>Profile</i> class term
      # objects representing all profile item values based on those associated with
      # the AMEE platform category with which <tt>self</tt> corresponds.
      #
      # Each term is instantiated with path, name, choices, default_unit and
      # default_per_unit attributes corresponding to those defined in the AMEE
      # platform.
      #
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

      # Helper method for automatically instantiating <i>Output</i> class term
      # objects representing all return values based on those associated with
      # the AMEE platform category with which <tt>self</tt> corresponds.
      #
      # Each term is instantiated with path, default_unit and default_per_unit
      # attributes corresponding to those defined in the AMEE platform.
      #
      def all_outputs
        amee_return_values.each do |rvd|
          output {
            path rvd.name
            default_unit rvd.unit
            default_per_unit rvd.perunit
          }
        end
      end

      # Helper method for automatically instantiating <i>Profile</i> class term
      # objects representing only the profile item values associated with a
      # particular usage (specified by <tt>usage</tt>) for the AMEE platform
      # category with which <tt>self</tt> corresponds.
      #
      # This method does not permit dynamic usage switching during run-time.
      #
      # Each term is instantiated with path, name, choices, default_unit and
      # default_per_unit attributes corresponding to those defined in the AMEE
      # platform.
      #
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

      # Helper method for automatically instantiating <i>Profile</i>, <i>Drill</i>
      # and <i>Output</i> class term objects representing all profile item values,
      # drill choices and return values associated with the AMEE platform category 
      # with which <tt>self</tt> corresponds.
      # 
      # Optionally, instantiate only those profile terms corresponding to a
      # particular usage by passing the path of the required usage as an argument.
      # The latter case does not allow dynamic usage switching at run-time.
      #
      # Each term is instantiated with path, name, choices, default_unit and
      # default_per_unit attributes corresponding to those defined in the AMEE
      # platform.
      #
      def terms_from_amee(usage=nil)
        all_drills
        if usage
          profiles_from_usage(usage)
        else
          all_profiles
        end
        all_outputs
      end

      # Helper method for automatically instantiating <i>Profile</i>, <i>Drill</i>
      # and <i>Output</i> class term objects representing all profile item values, 
      # drill choices and return values associated with the AMEE platform category 
      # with which <tt>self</tt> corresponds.
      # 
      # Also automatically defines a usage term for the usage represented by
      # <tt>ausage</tt> to enable dynamic usage switching. The profile terms
      # associated with the specified usage are automatically activated and
      # deactivated as appropriate, but this can be switched at run-time by
      # changing the value of the instantiated usage term.
      #
      # Each term is instantiated with path, name, choices, default_unit and
      # default_per_unit attributes (where appropriate) corresponding to those
      # defined in the AMEE platform.
      #
      def terms_from_amee_dynamic_usage(ausage)
        all_drills
        usage{ value ausage}
        all_outputs
      end

      # Helper method for automatically instantiating <i>Profile</i> class term
      # objects representing all profile item values associated with the AMEE
      # platform category represented by <tt>self</tt>, and instantiating a new instance
      # of the <i>Usage</i> term class which can be used for dynamically switching
      # usages at run-time.
      #
      # Each term is instantiated with path, name, choices, default_unit and
      # default_per_unit attributes corresponding to those defined in the AMEE
      # platform.
      #
      # The newly instantiated <i>Usage</i> object can be configured in place
      # according to the ('DSL') block passed in, e.g.,
      #
      #   my_protptype.usage {
      #     inactive :disabled
      #     value nil
      #   }
      #
      def usage(options={},&block)
        all_profiles
        construct(Usage,options.merge(:first=>true),&block)
      end

      # Helper method for automatically instantiating <i>Metadatum</i> class term 
      # objects explicitly configured for storing start and end dates for an AMEE
      # platform profile item.
      #
      def start_and_end_dates
        metadatum {
          path 'start_date'
          name 'Start date'
          interface :date
          type :datetime
          validation lambda{|v| v.is_a?(Time) || v.is_a?(DateTime) || (v.is_a?(String) && Date.parse(v) rescue false)}
        }
        metadatum {
          path 'end_date'
          name 'End date'
          interface :date
          type :datetime
          validation lambda{|v| v.is_a?(Time) || v.is_a?(DateTime) || (v.is_a?(String) && Date.parse(v) rescue false)}
        }
      end

      # Helper method for reopening and modifying the definition of the term with
      # the label attribute matching <tt>label</tt>. Modification is specified in
      # the passed block, which is evaluated in the context of the respective term
      # instance.
      #
      # This is typically used to override (customize) the attributes and behaviour
      # of term autoloaded from the AMEE platform using one of the instance helper
      # methods of <tt>self</tt>.
      #
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