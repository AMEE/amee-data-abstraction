module AMEE
  module DataAbstraction
    class Term

      public

      attr_property :label,:name,:value,:path,:interface
            
      attr_accessor :parent

      def initialize(options={},&block)
        @parent=options[:parent]
        @value=nil
        @enabled=true
        @visible=true
        instance_eval(&block) if block
        label path.to_s.underscore.to_sym unless path.blank?||label
        path label.to_s unless path
        name label.to_s.humanize unless name
        unit default_unit unless unit
        per_unit default_per_unit unless per_unit
      end

      Interfaces=[:text_box,:drop_down,:date]

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

      UnitFields = [:unit,:per_unit,:default_unit,:default_per_unit]

      # Define explicit methods for setting and getting default and current units
      # and per units. These replace the attr_property methods since initialization
      # of unit objects is required
      #
      UnitFields.each do |field|
        define_method(field) do |*unit|
          instance_variable_set("@#{field}",Unit.for(unit.first)) unless unit.empty?
          instance_variable_get("@#{field}")
        end
      end

      # Define explicit methods for setting and getting unit alternatives. If not
      # explicitly defined, default to the dimensionally equivalent units of the
      # default units. This replaces the attr_property methods since initialization
      # of unit objects is required
      #
      [:unit,:per_unit].each do |field|
        define_method("alternative_#{field}s") do |*args|
          ivar = "@alternative_#{field}s"
          default = send("default_#{field}".to_sym)
          unless args.empty?
            args << default if default
            units = args.map {|arg| Unit.for(arg) }
            Term.validate_dimensional_equivalence?(*units)
            instance_variable_set(ivar, units)
          else
            return instance_variable_get(ivar) if instance_variable_get(ivar)
            return instance_variable_set(ivar, (default.alternatives << default)) if default
          end
        end
      end

      def set?
        !value.nil?
      end

      def unset?
        value.nil?
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

      def before?(lab)
         parent.terms.labels.index(lab)>parent.terms.labels.index(label)
      end

      def after?(lab)
        parent.terms.labels.index(lab)<parent.terms.labels.index(label)
      end

      def initialize_copy(source)
        super
        UnitFields.each do |property|
          prop = send(property)
          self.send(property, prop.clone) unless prop.nil?
        end
      end

      # String representation of term. Format argument describes the format in which
      # units should be rendered, and default to the unit symbol. Alternative options
      # include :name, :pluralized_name and :label
      #
      def to_s(format=:symbol)
        string = "#{value}"
        if unit and per_unit
          string += " #{(unit/per_unit).send(format)}"
        elsif unit
          string += " #{unit.send(format)}"
        elsif per_unit
          string += " #{(1/per_unit).send(format)}"
        end
        return string
      end

      # Check that the supplied units are dimensionally equivalent
      def self.validate_dimensional_equivalence?(*units)
        unless [units].flatten.all? {|unit| unit.dimensions == units[0].dimensions }
          raise AMEE::DataAbstraction::Exceptions::InvalidUnits,
            "The specified term units are not of equivalent dimensions: #{units.map(&:label).join(",")}"
        end
      end
      
    end
  end
end