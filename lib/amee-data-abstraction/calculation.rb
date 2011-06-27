module AMEE
  module DataAbstraction

    # Base class representing a calculation which can be done using AMEE.
    # Derived classes:
    # * PrototypeCalculation : represents potential calculations, which need to have values filled in for drills and profile items
    # * OngoingCalculation : a particular calculation for a given user, possibly incomplete.
    class Calculation

      public
      # accessors:
      # * label : symbol giving machine-read name for the calculation
      # * name : string giving human-readable label for the calculation
      # * path : path to the AMEE data category to be used for the calculation
      # * fixed_usage : if there is an AMEE usage to be used for the calculation, string giving its value.
      attr_property :label,:name,:path,:fixed_usage

      # Calculation will contain a list of "terms", inputs, outputs etc.
      # this method will retrieve that list, as a TermsList class.
      def terms
        TermsList.new(@contents.values)
      end

      # Retrieve the terms, as a hash from labels to terms.
      attr_accessor :contents

      # Retrieve the term, labelled with the given symbol
      def [](sym)
        @contents[sym.to_sym]
      end

      #Sugar to allow, e.g. mycalc.drills
      TermsList::Selectors.each do |sel|
        delegate sel,:to=>:terms
      end

      #Prettyprint the calculation and its terms
      def inspect
        "#{label} : [#{terms.values.map{|x| x.inspect}.join(',')}]"
      end

      def initialize_copy(source)
        super
        @contents=ActiveSupport::OrderedHash.new
        source.contents.each do |k,v|
          @contents[k]=v.clone
          @contents[k].parent=self
        end
      end

      # URL on explorer corresponding to this calculation
      def explorer_url
         "http://explorer.amee.com/categories#{path}"
      end
       
      protected

      def initialize
        @contents=ActiveSupport::OrderedHash.new
      end

      #Methods which will be memoized at application start, as they do not
      #change over application instance lifetime
      AmeeMemoised=[:amee_data_category, :amee_item_definition, :amee_ivds,
        :amee_return_values, :amee_usages]

      # Obtain all the values of the memoized quantities
      def saved_amee
        AmeeMemoised.map{|x|instance_variable_get("@#{x.to_s}")}
      end

      # Save the memoized quantities to their instance variables
      def save_amee(values)
        AmeeMemoised.zip(values).each do |prop,val|
          instance_variable_set("@#{prop.to_s}",val)
        end
      end

      private

      def connection
        AMEE::DataAbstraction.connection
      end

      def amee_data_category
        @amee_data_category||=AMEE::Data::Category.get(connection, "/data#{path}")
      end

      def amee_item_definition
        @amee_item_definition||=amee_data_category.item_definition
      end

      def amee_return_values
        @amee_return_values||=AMEE::Admin::ReturnValueDefinitionList.new(connection,amee_item_definition.uid)
      end

      def by_path(path)
        terms.detect { |v| v.path==path }
      end

      def drill_by_path(path)
        drills.detect { |v| v.path==path }
      end

      public #friend to Term

      def amee_ivds
        @amee_ivds||=amee_item_definition.item_value_definition_list.select{|x|x.versions.include?("2.0")}
      end

      # The value of a usage term, if there is one, or a fixed usage, or nil.
      def current_usage
        usages.empty? ? fixed_usage : usages.first.value
      end

      # Available usages in the AMEE item definition.
      def amee_usages
        @amee_usages||=amee_item_definition.usages
      end

    end
  end
end