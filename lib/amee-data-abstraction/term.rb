module AMEE
  module DataAbstraction
    #Base class for quantities which are inputs to, or outputs from, a calculation.
    #Subclasses correspond to:
    #* Input
    #* * Profile -- profile item value
    #* * Drill -- drill down
    #* * Usage -- runtime adjustable usage choice
    #* * Metadatum -- other inputs
    #* Output
    class Term

      public

      # Machine readable symbol label for the term
      attr_property :label

      # Human readable description for the term
      attr_property :name

      # Value of the term, can be a numeric type or a quantify Quantity.
      attr_property :value

      # Path on AMEE for a drill or profile term.
      attr_property :path

      # Suggestion of the type of user interface element, a symbol from the
      # Interfaces constant array.
      attr_property :interface

      # Who defined this? I don't know what it's for.
      attr_property :note

      # The owning DB::Calculation.
      attr_accessor :parent

      # Construct the term with a supplied DSL block.
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
        # should add in here auto setting of :note property using ivd annotation
      end

      # Valid choices for suggested interfaces for a term.
      # Methods such as text_box? are generated to see which value has been chosen.
      Interfaces=[:text_box,:drop_down,:date]

      Interfaces.each do |inf|
        define_method("#{inf.to_s}?") {
          interface==inf
        }
      end

      #Set the suggested UI element to the given value, or retrieve the current value.
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

      # Has a value been given for the term?
      def set?
        !value.nil?
      end

      # Has the term not yet been assigned a value?
      def unset?
        value.nil?
      end

      # Declare that the term's UI element should be disabled in generated UIs.
      def disable!
        @disabled=true
      end

      # Declare that the term's UI element should be enabled in generated UIs.
      def enable!
        @disabled=false
      end

      # Should the term's UI element be disabled (e.g. greyed out) in generated UIs?
      def disabled?
        @disabled
      end

      # Should the term's UI element be enabled in generated UIs?
      def enabled?
        !disabled?
      end

      # Should the term's UI element be displayed in generated UIs?
      def visible?
        @visible
      end

      # Should the term's UI element be non-displayed in generated UIs?
      def hidden?
        !visible?
      end

      # Declare that the term's UI element should not be shown in generated UIs.
      def hide!
        @visible=false
      end

      # Declare that the term's UI element should be shown in generated UIs.
      def show!
        @visible=true
      end

      # Is the value numeric? That is, can it have statistics applied?
      # Permits handling of term summing, averaging, etc.
      def has_numeric_value?
        set? and Float(value) rescue false
      end

      def inspect
        "[#{self.class} #{label} : #{value}]"
      end

      # Does the term occur before the term with the given label?
      def before?(lab)
         parent.terms.labels.index(lab)>parent.terms.labels.index(label)
      end

      # Does the term occur after the term with the given label?
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