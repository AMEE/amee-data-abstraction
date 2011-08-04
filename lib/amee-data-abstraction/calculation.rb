
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
# :title: Class: AMEE::DataAbstraction::Calculation

module AMEE
  module DataAbstraction

    # Base class providing attributes and methods for representing a calculation
    # which can be made using the AMEE platform. An instance of <i>Calculation</i>
    # will typically be associated with a specific AMEE category.
    #
    # Instances of <i>Calculation</i> are represented by several primary attributes:
    #
    #   label::       Symbol representing the unique, machine-readable name for the
    #                 calculation
    #
    #   name::        String representing a human-readable name for the calculation
    #
    #   path::        String representing the AMEE platform path to the data category
    #                 which is associated with <tt>self</tt>
    #
    #   fixed_usage:: String representing the AMEE platform path for the usage to
    #                 be used by <tt>self</tt>, if defined
    #
    # An instance of <i>Calculation</i> also holds an arbitrary number of objects
    # of the class <i>Term</i>. These represent values associated with the
    # calculation, e.g. inputs, outputs, metadatum, etc. These can be accessed
    # using the <tt>#terms</tt> methods or the term subset methods provided by
    # the <tt>TermsList</tt> class (e.g. <tt>#profiles</tt>, <tt>#visible</tt>)
    #
    # Two classes inherit the <i>Calculation</i> class:
    # * <i>PrototypeCalculation</i> : provides a templating for a specific calculation
    #   type with defined, but blank, terms (i.e. inputs, outputs, etc.)
    #
    # * <i>OngoingCalculation</i> : represents a particular calculation - possibly
    #   incomplete - which can be updated, submitted for calculation, and saved
    #
    class Calculation

      public

      # Symbol representing the unique, machine-readable name for <tt>self</tt>.
      # Set a value by passing an argument. Retrieve a value by calling without
      # an argument, e.g.,
      #
      #  my_calculation.label :fuel
      #
      #  my_calculation.label               #=> :fuel
      #
      attr_property :label

      # String representing a human-readable name for <tt>self</tt>. Set a
      # value by passing an argument. Retrieve a value by calling without an
      # argument, e.g.,
      #
      #  my_calculation.name 'Domestic fuel consumption'
      #
      #  my_calculation.name               #=> 'Domestic fuel consumption'
      #
      attr_property :name

      # String representing the AMEE platform path to the data category which is
      # associated with <tt>self</tt>. Set a value by passing an argument. Retrieve
      # a value by calling without an argument, e.g.,
      #
      #  my_calculation.path '/some/path/in/amee/'
      #
      #  my_calculation.path               #=> '/some/path/in/amee/'
      #
      attr_property :path

      # String representing the AMEE platform path for the usage to be used by
      # <tt>self</tt>, if defined. Set a value by passing an argument. Retrieve
      # a value by calling without an argument, e.g.,
      #
      #  my_calculation.fixed_usage 'byMass'
      #
      #  my_calculation.fixed_usage        #=> 'byMass'
      #
      attr_property :fixed_usage

      # Calculations contain a list of "terms" of the base class <i>Term</i>,
      # representing inputs, outputs, metadatum, etc. which are associated with
      # <tt>self</tt>.
      # 
      # Returns all associated terms as an instance of the <i>TermsList</i> class
      #
      def terms
        TermsList.new(@contents.values)
      end

      # Retrieve the terms associated with <tt>self</tt> as a hash from labels to terms.
      attr_accessor :contents

      # Shorthand method for retrieving the term assocaited with <tt>self</tt> which has a
      # label matching <tt>sym</tt>
      #
      def [](sym)
        @contents[sym.to_sym]
      end

      # Syntactic sugar to enable the return of a subset of associated terms according
      # to their type or status (e.g. drills, profiles, set, unset, visible). See
      # <i>TermsList::Selectors</i> for valid variants
      #
      TermsList::Selectors.each do |sel|
        delegate sel,:to=>:terms
      end

      # Prettyprint a string representation of <tt>self</tt>, together with associated terms
      def inspect
        elements = {:label => label.inspect, :terms => terms.map{|t| "<#{t.class.name.demodulize} label:#{t.label}, value:#{t.value.inspect}>"}}
        attr_list = elements.map {|k,v| "#{k}: #{v}" } * ', '
        "<#{self.class.name} #{attr_list}>"
      end

      def initialize_copy(source)
        super
        @contents=ActiveSupport::OrderedHash.new
        source.contents.each do |k,v|
          @contents[k]=v.clone
          @contents[k].parent=self
        end
      end

      # Return a string representing the AMEE Explorer URL which is assocaited
      # with <tt>self</tt>
      #
      def explorer_url
         "http://explorer.amee.com/categories#{path}"
      end
       
      protected

      def initialize
        @contents=ActiveSupport::OrderedHash.new
      end

      # Methods which will be memoized at application start, as they do not
      # change over application instance lifetime
      #
      AmeeMemoised=[:amee_data_category, :amee_item_definition, :amee_ivds,
        :amee_return_values, :amee_usages]

      # Return all the values of the memoized quantities
      def saved_amee
        AmeeMemoised.map{|x|instance_variable_get("@#{x.to_s}")}
      end

      # Save the memoized quantities
      def save_amee(values)
        AmeeMemoised.zip(values).each do |prop,val|
          instance_variable_set("@#{prop.to_s}",val)
        end
      end

      private

      # Return the global <i>AMEE::Connection</i> object. This is configured in
      # /config/amee.yml
      #
      def connection
        AMEE::DataAbstraction.connection
      end

      # Return the <i>AMEE::Data::Category</i> object associated with <tt>self</tt>
      def amee_data_category
        @amee_data_category||=AMEE::Data::Category.get(connection, "/data#{path}")
      end

      # Return the <i>AMEE::Admin::ItemDefinition</i> object associated with <tt>self</tt>
      def amee_item_definition
        @amee_item_definition||=amee_data_category.item_definition
      end

      # Return the <i>AMEE::Admin::ReturnValueDefinitionList</i> object associated
      # with <tt>self</tt>. This represents each of the return value definitions which are
      # associated with the calculation
      #
      def amee_return_values
        @amee_return_values||=AMEE::Admin::ReturnValueDefinitionList.new(connection,amee_item_definition.uid)
      end

      # Return the instance of <i>Term</i> class associated with <tt>self</tt> and contains
      # a path attribute matching <tt>path</tt>, e.g.
      #
      #   my_calculation.by_path('distance') #=> <AMEE::DataAbstraction::Profile ... >
      #
      #   my_calculation.by_path('type')     #=> <AMEE::DataAbstraction::Drill ... >
      #
      def by_path(path)
        terms.detect { |v| v.path==path }
      end

      # Return the instance of <i>Drill</i> class associated with <tt>self</tt> and contains
      # a path attribute matching <tt>path</tt>, e.g.
      # 
      #   my_calculation.by_path('type')     #=> <AMEE::DataAbstraction::Drill ... >
      #
      def drill_by_path(path)
        drills.detect { |v| v.path==path }
      end

      public

      # Return the <i>AMEE::Admin::ItemValueDefinitionList</i> object associated
      # with <tt>self</tt>. This represents each of the item value definitions which are
      # associated with the calculation
      #
      def amee_ivds
        @amee_ivds||=amee_item_definition.item_value_definition_list.select{|x|x.versions.include?("2.0")}
      end

      # Returns a String representing the AMEE platform path for the usage currently
      # used by <tt>self</tt>. If not usage is defined, returns nil
      #
      #   my_calculation.current_usage      #=> 'byMass'
      #
      def current_usage
        usages.empty? ? fixed_usage : usages.first.value
      end

      # Returns an Array containing the AMEE platform paths for all valid usage
      # available to <tt>self</tt> according to those defined under #item_definition. If
      # no usage(s) is defined, returns nil, e.g.
      #
      #   my_calculation.amee_usages      #=> [ 'byMass', 'byEnergy' ]
      #
      def amee_usages
        @amee_usages||=amee_item_definition.usages
      end

    end
  end
end