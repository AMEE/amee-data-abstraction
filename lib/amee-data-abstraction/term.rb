module AMEE
  module DataAbstraction
    class Term

      public

      #DSL----

      attr_property :label,:name,:value,:path,:unit,:other_acceptable_units,:interface
            
      #-------

      attr_accessor :parent

      def initialize(options={},&block)
        @parent=options[:parent]
        @value=nil
        @enabled=true
        @visible=true
        instance_eval(&block) if block
        path label.to_s unless path
        name label.to_s.humanize unless name
      end


      Interfaces=[:text_box,:drop_down]

      Interfaces.each do |inf|
        define_method("#{inf.to_s}?") {
          interface==inf
        }
      end

      def interface(inf=nil)
        if inf
          raise Exceptions::InvalidInterface unless Interfaces.include? inf
          @interface=inf
        end
        return @interface
      end

      def set?
        !value.nil?
      end

      def disable!
        @disabled=true
      end

      def enable!
        @disabled=false
      end

      def disabled?
        @disabled
      end

      def enabled?
        !disabled?
      end

      def visible?
        @visible
      end

      def hidden?
        !visible?
      end

      def hide!
        @visible=false
      end

      def show!
        @visible=true
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