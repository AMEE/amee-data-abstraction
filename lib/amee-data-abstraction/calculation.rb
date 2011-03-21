module AMEE
  module DataAbstraction
    class Calculation

      public
      
      attr_property :label,:name,:path

      def [](sym)
        @terms[sym.to_sym]
      end

      def inputs
        terms Input
      end

      
      def outputs
        terms Output
      end

      def after(label,klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|v.after?(label)}]
      end

      def before(label,klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|v.before?(label)}]
      end

      def inspect
        "#{label} : [#{terms.values.map{|x| x.inspect}.join(',')}]"
      end

      def initialize_copy(source)
        super
        @terms=ActiveSupport::OrderedHash.new
        source.terms.each do |k,v|
          @terms[k]=v.clone
          @terms[k].parent=self
        end
      end

      def terms(klass=nil)
        return @terms unless klass
        ActiveSupport::OrderedHash[@terms.stable_select{|k,v| v.is_a? klass}]
      end

      protected

      def initialize
        @terms=ActiveSupport::OrderedHash.new
      end

      private

      def by_path(path)
        @terms.values.detect { |v| v.path==path }
      end

      def drill_by_path(path)
        drills.values.detect { |v| v.path==path }
      end

      def profiles
        terms Profile
      end

      def drills
        terms Drill
      end


    end
  end
end