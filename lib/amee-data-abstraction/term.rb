module AMEE
  module DataAbstraction
    class Term

      public

      #DSL----

      attr_property :label,:name,:path,:value,:type,:validation,:unit,:other_acceptable_units,:default
      
      
      #-------

      attr_accessor :parent

      def initialize(options={},&block)
        @parent=options[:parent]
        @value=nil
        instance_eval(&block) if block
      end

      def set?
        !value.nil?
      end

      def value_if_given
        set? ? value : nil
      end

      def inspect
        "[#{self.class} #{label} : #{value}]"
      end

      private
            
      def siblings
        parent.terms(self.class)
      end
      def chosen_siblings
        parent.chosen_terms(self.class)
      end
      def unset_siblings
        parent.unset_terms(self.class)
      end
      
      def unset_others
        ActiveSupport::OrderedHash[parent.unset_terms(self.class).reject{|k,v|
            k==label
          }]
      end   
    end
  end
end