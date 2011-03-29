module AMEE
  module DataAbstraction
    class Calculation

      public
      
      attr_property :label,:name,:path,:fixed_usage
      
      def terms
        TermsList.new(@contents.values)
      end

      attr_accessor :contents

      def [](sym)
        @contents[sym.to_sym]
      end

      #Sugar to allow, e.g. mycalc.drills
      TermsList::Selectors.each do |sel|
        delegate sel,:to=>:terms
      end

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

      protected

      def initialize
        @contents=ActiveSupport::OrderedHash.new
      end

      private

      def connection
        AMEE::DataAbstraction.connection
      end

      def amee_data_category
        AMEE::Data::Category.get(connection, "/data#{path}")
      end

      def amee_item_definition
        amee_data_category.item_definition
      end

      def by_path(path)
        terms.detect { |v| v.path==path }
      end

      def drill_by_path(path)
        drills.detect { |v| v.path==path }
      end

      public #friend to Term

      def amee_ivds
        amee_item_definition.item_value_definition_list.select{|x|x.versions.include?("2.0")}
      end

      def current_usage
        usages.empty? ? fixed_usage : usages.first.value
      end

      def amee_usages
        amee_item_definition.usages
      end

    end
  end
end