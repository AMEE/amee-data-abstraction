module AMEE
  module DataAbstraction
    class Calculation

      public
      
      attr_property :label,:name,:path
      
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

      def by_path(path)
        terms.detect { |v| v.path==path }
      end

      def drill_by_path(path)
        drills.detect { |v| v.path==path }
      end

    end
  end
end