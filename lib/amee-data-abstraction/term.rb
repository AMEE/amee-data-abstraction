# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: AMEE::DataAbstraction::Term
require 'bigdecimal'

module AMEE
  module DataAbstraction

    # Base class for representing quantities which are inputs to, outputs of, or
    # metadata associated with, calculations. Typically several instances of the
    # <i>Term</i> class (or subclasses) will be associated with instances of the
    # <i>Calculation</i> class or its subclasses (<i>PrototypeCalculation</i>,
    # <i>OngoingCalculation</i>).
    #
    # Instances of <i>Term</i> are represented by several primary attributes:
    #
    #   label::       Symbol representing the unique, machine-readable name for the
    #                 term (<b>required</b>)
    #
    #   value::       In principle, any object which represent the desired value
    #                 which the term represents
    #
    #   name::        String representing a human-readable name for the term
    #
    #   path::        String representing the AMEE platform path to the AMEE item
    #                 value definition which is associated with <tt>self</tt>.
    #                 This attribute is required only if the term represents an
    #                 item value definition in the AMEE platform
    #
    # Other available attribute-like methods include <tt>type</tt>,
    # <tt>interface</tt>, <tt>note</tt>, <tt>unit</tt>, <tt>per_unit</tt>, 
    # <tt>default_unit</tt>, <tt>default_per_unit</tt> and <tt>parent</tt>.
    #
    # Subclasses of the <i>Term</i> correspond to:
    # * <i>Input</i>
    # * * <i>Profile</i> -- corresponds to an AMEE profile item value
    # * * <i>Drill</i> -- corresponds to an AMEE drill down choice
    # * * <i>Usage</i> -- corresponds to a (runtime adjustable) AMEE usage choice
    # * * <i>Metadatum</i> -- represents other arbitrary inputs
    # * <i>Output</i> -- corresponds to an AMEE return value
    #
    class Term

      public

      # Symbol representing the unique (within the parent calculation), machine-
      # readable name for <tt>self</tt>. Set a value by passing an argument.
      # Retrieve a value by calling without an argument, e.g.,
      #
      #  my_term.label :distance
      #
      #  my_term.label               #=> :distance
      #
      attr_property :label

      # String representing a human-readable name for <tt>self</tt>. Set a value
      # by passing an argument. Retrieve a value by calling without an argument,
      # e.g.,
      #
      #  my_term.name 'Distance driven'
      #
      #  my_term.name                       #=> 'Distance driven'
      #
      attr_property :name

      # Symbol representing the class the value should be parsed to.  If
      # omitted a string is assumed, e.g.:
      #
      # my_term.type :integer
      # my_term.value "12"
      # my_term.value                        # => 12
      # my_term.value_before_cast            # => "12"
      #
      attr_property :type

      # String representing a the AMEE platform path for <tt>self</tt>. Set a
      # value by passing an argument. Retrieve a value by calling without an
      # argument, e.g.,
      #
      #  my_term.path 'mass'
      #
      #  my_term.path                       #=> 'mass'
      #
      attr_property :path

      # Symbol representing the owning parent calculation of <tt>self</tt>. Set
      # the owning calculation object by passing as an argument. Retrieve it by
      # calling without an argument, e.g.,
      #
      #  my_calculation = <AMEE::DataAbstraction::OngoingCalculation ... >
      #
      #  my_term.parent my_calculation
      #
      #  my_term.parent            #=> <AMEE::DataAbstraction::OngoingCalculation ... >
      #
      attr_accessor :parent
      
      # Stores pre-cast value
      attr_accessor :value_before_cast

      # Initialize a new instance of <i>Term</i>.
      #
      # The term can be configured in place by passing a block (evaluated in the
      # context of the new instance) which defines the term properties using the
      # macro-style instance helper methods.
      #
      #   my_term = Term.new {
      #
      #     label :size
      #     path "vehicleSize"
      #     hide!
      #     ...
      #   }
      #
      # The parent calculation object associated with <tt>self</tt> can be assigned 
      # using the :parent hash key passed as an argument.
      #
      # Unless otherwise configured within the passed block, several attributes
      # attempt to take default configurations if possible using rules of thumb:
      #
      # * value          => <tt>nil</tt>
      # * enabled        => <tt>true</tt>
      # * visible        => <tt>true</tt>
      # * label          => underscored, symbolized version of <tt>path</tt>
      # * path           => stringified version of <tt>label</tt>
      # * name           => stringified and humanised version of <tt>label</tt>
      # * unit           => <tt>default_unit</tt>
      # * per_unit       => <tt>default_per_unit</tt>
      #
      def initialize(options={},&block)
        @parent=options[:parent]
        @value=nil
        @type=nil
        @enabled=true
        @visible=true
        instance_eval(&block) if block
        label path.to_s.underscore.to_sym unless path.blank?||label
        path label.to_s unless path
        name label.to_s.humanize unless name
        unit default_unit unless unit
        per_unit default_per_unit unless per_unit
      end

      # Valid choices for suggested interfaces for a term.
      # Dynamic boolean methods (such as <tt>text_box?</tt>) are generated for
      # checking which value is set.
      # 
      #   my_term.drop_down?                #=> true
      #
      Interfaces=[:text_box,:drop_down,:date]

      Interfaces.each do |inf|
        define_method("#{inf.to_s}?") {
          interface==inf
        }
      end

      # Symbolized attribute representing the expected interface type for
      # <tt>self</tt>. Set a value by passing an argument. Retrieve a value by
      # calling without an argument, e.g.,
      #
      #  my_term.interface :drop_down
      #
      #  my_term.interface                  #=> :drop_down
      #
      # Must represent one of the valid choices defined in the
      # <i>Term::Interfaces</i> constant
      #
      # If the provided interface is not valid (as defined in <i>Term::Interfaces</i>)
      #  an <i>InvalidInterface</i> exception is raised
      # 
      def interface(inf=nil)
        if inf
          raise Exceptions::InvalidInterface unless Interfaces.include? inf
          @interface=inf
        end
        return @interface
      end

      # Object representing the value which <tt>self</tt> is considered to
      # represent (e.g. the quantity or name of something). Set a value by
      # passing an argument. Retrieve a value by calling without an argument,
      # e.g.,
      #
      #  my_term.value 12
      #  my_term.value                      #=> 12
      #
      #
      #  my_term.value 'Ford Escort'
      #  my_term.value                      #=> 'Ford Escort'
      #
      #
      #  my_term.value DateTime.civil(2010,12,31)
      #  my_term.value                      #=> <Date: 4911123/2,0,2299161>
      #
      def value(*args)
        unless args.empty?
          @value_before_cast = args.first
          @value = @type ? self.class.convert_value_to_type(args.first, @type) : args.first
        end
        @value
      end

      # String representing an annotation for <tt>self</tt>. Set a value by
      # passing an argument. Retrieve a value by calling without an argument,
      # e.g.,
      #
      #  my_term.note 'Enter the mass of cement produced in the reporting period'
      #
      #  my_term.note                       #=> 'Enter the mass of cement ...'
      #
      def note(string=nil)
        instance_variable_set("@note",string.gsub('"',"'")) unless string.nil?
        instance_variable_get("@note")
      end
      
      # Symbols representing the attributes of <tt>self</tt> which are concerned
      # with quantity units.
      #
      # Each symbol also represents <b>dynamically defined method<b> name for
      # setting and retrieving the default and current units and per units. Units
      # are initialized as instances of <i>Quantify::Unit::Base</tt> is required.
      #
      # Set a unit attribute by passing an argument. Retrieve a value by calling
      # without an argument. Unit attributes can be defined by any form which is
      # accepted by the <i>Quantify::Unit#for</i> method (either an instance of
      # <i>Quantify::Unit::Base</i> (or subclass) or a symbolized or string
      # representation of the a unit symbol, name or label). E.g.,
      #
      #  my_term.unit :mi
      #  my_term.unit                   #=> <Quantify::Unit::NonSI:0xb71cac48 @label="mi" ... >
      #
      #  my_term.default_unit 'feet'
      #  my_term.default_unit           #=> <Quantify::Unit::NonSI:0xb71cac48 @label="ft" ... >
      #
      #
      #  my_time_unit = Unit.hour       #=> <Quantify::Unit::NonSI:0xb71cac48 @label="h" ... >
      #  my_term.default_per_unit my_time_unit
      #  my_term.default_per_unit       #=> <Quantify::Unit::NonSI:0xb71cac48 @label="h" ... >
      #
      #
      # Dynamically defined methods are also available for setting and retrieving
      # alternative units for the <tt>unit</tt> and <tt>per_unit</tt> attributes.
      # If no alternative units are explicitly defined, they are instantiated by
      # default to represent all dimensionally equivalent units available in the
      # system of units defined by <i>Quantify</i>. E.g.
      #
      #   my_term.unit :kg
      #   my_term.alternative_units     #=> [ <Quantify::Unit::NonSI:0xb71cac48 @label="mi" ... >,
      #                                       <Quantify::Unit::SI:0xb71cac48 @label="km" ... >,
      #                                       <Quantify::Unit::NonSI:0xb71cac48 @label="ft" ... >,
      #                                       ... ]
      #
      #   my_term.unit 'litre'
      #   my_term.alternative_units :bbl, :gal
      #   my_term.alternative_units     #=> [ <Quantify::Unit::NonSI:0xb71cac48 @label="bbl" ... >,
      #                                       <Quantify::Unit::NonSI:0xb71cac48 @label="gal" ... > ]
      #
      UnitFields = [:unit,:per_unit,:default_unit,:default_per_unit]

      UnitFields.each do |field|
        define_method(field) do |*unit|
          instance_variable_set("@#{field}",Unit.for(unit.first)) unless unit.empty?
          instance_variable_get("@#{field}")
        end
      end

      [:unit,:per_unit].each do |field|

        # If no argument provided, returns the alternative units which are valid
        # for <tt>self</tt>. If a list of units are provided as an argument, these
        # override the dynamically assigned alternative units for <tt>self</tt>.
        #
        define_method("alternative_#{field}s") do |*args|
          ivar = "@alternative_#{field}s"
          unless args.empty?
            units = args.map {|arg| Unit.for(arg) }
            Term.validate_dimensional_equivalence?(*units)
            instance_variable_set(ivar, units)
          else
            return instance_variable_get(ivar) if instance_variable_get(ivar)
            default = send("default_#{field}".to_sym)
            return instance_variable_set(ivar, (default.alternatives)) if default
          end
        end

        # Returns the list of unit choices for <tt>self</tt>, including both the
        # default unit and all alternative units.
        #
        define_method("#{field}_choices") do |*args|
          choices = send("alternative_#{field}s".to_sym)
          default = send("default_#{field}".to_sym)
          choices = [default] + choices if default
          return choices
        end
      end

      # Returns <tt>true</tt> if <tt>self</tt> has a populated value attribute.
      # Otherwise, returns <tt>false</tt>.
      #
      def set?
        !value_before_cast.nil?
      end

      # Returns <tt>true</tt> if <tt>self</tt> does not have a populated value
      # attribute. Otherwise, returns <tt>false</tt>.
      #
      def unset?
        value_before_cast.nil?
      end

      # Declare that the term's UI element should be disabled
      def disable!
        @disabled=true
      end

      # Declare that the term's UI element should be enabled
      def enable!
        @disabled=false
      end

      # Returns <tt>true</tt> if the UI element of <tt>self</tt> is disabled.
      # Otherwise, returns <tt>false</tt>.
      #
      def disabled?
        @disabled
      end

      # Returns <tt>true</tt> if the UI element of <tt>self</tt> is enabled.
      # Otherwise, returns <tt>false</tt>.
      #
      def enabled?
        !disabled?
      end

      # Returns <tt>true</tt> if <tt>self</tt> is configured as visible.
      # Otherwise, returns <tt>false</tt>.
      #
      def visible?
        @visible
      end

      # Returns <tt>true</tt> if <tt>self</tt> is configured as hidden.
      # Otherwise, returns <tt>false</tt>.
      #
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

      def ==(other_term)
        !TermsList::TermProperties.inject(false) do |boolean,prop|
          boolean || self.send(prop) != other_term.send(prop)
        end
      end

      # Returns <tt>true</tt> if <tt>self</tt> has a numeric value. That is, can 
      # it have statistics applied? This method permits handling of term summing,
      #  averaging, etc. Otherwise, returns <tt>false</tt>.
      #
      def has_numeric_value?
        is_numeric? && set? && Float(value) rescue false
      end

      def is_numeric?
        ![:string, :text, :datetime, :time, :date ].include?(type)
      end

      # Returns a pretty print string representation of <tt>self</tt>
      def inspect
        elements = {:label => label, :value => value, :unit => unit,
                    :per_unit => per_unit, :type => type,
                    :disabled => disabled?, :visible => visible?}
        attr_list = elements.map {|k,v| "#{k}: #{v.inspect}" } * ', '
        "<#{self.class.name} #{attr_list}>"
      end

      # Returns <tt>true</tt> if <tt>self</tt> occurs before the term with a label
      # matching <tt>lab</tt> in the terms list of the parent calculation. Otherwise,
      # returns <tt>false</tt>.
      #
      def before?(lab)
         parent.terms.labels.index(lab)>parent.terms.labels.index(label)
      end

      # Returns <tt>true</tt> if <tt>self</tt> occurs after the term with a label
      # matching <tt>lab</tt> in the terms list of the parent calculation. Otherwise,
      # returns <tt>false</tt>.
      #
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

      # Return a new instance of <i>Term</i>, based on <tt>self</tt> but with
      # a change of units, according to the <tt>options</tt> hash provided, and
      # the value attribute updated to reflect the new units.
      #
      # To specify a new unit, pass the required unit via the <tt>:unit</tt> key.
      # To specify a new per_unit, pass the required per unit via the
      # <tt>:per_unit</tt> key. E.g.,
      #
      #   my_term.convert_unit(:unit => :kg)
      #
      #   my_term.convert_unit(:unit => :kg, :per_unit => :h)
      #
      #   my_term.convert_unit(:unit => 'kilogram')
      #
      #   my_term.convert_unit(:per_unit => Quantify::Unit.h)
      #
      #   my_term.convert_unit(:unit => <Quantify::Unit::SI ... >)
      #
      # If <tt>self</tt> does not hold a numeric value or either a unit or per
      # unit attribute, <tt>self</tt> is returned.
      #
      def convert_unit(options={})
        return self unless is_numeric? && (unit || per_unit)

        new = clone
        if has_numeric_value?
          if options[:unit] && unit
            new_unit = Unit.for(options[:unit])
            Term.validate_dimensional_equivalence?(unit,new_unit)
            new.value Quantity.new(new.value,new.unit).to(new_unit).value
          end
          if options[:per_unit] && per_unit
            new_per_unit = Unit.for(options[:per_unit])
            Term.validate_dimensional_equivalence?(per_unit,new_per_unit)
            new.value Quantity.new(new.value,(1/new.per_unit)).to(Unit.for(new_per_unit)).value
          end
        end
        new.unit options[:unit] if options[:unit]
        new.per_unit options[:per_unit] if options[:per_unit]
        return new
      end

      # Return an instance of Quantify::Quantity describing the quantity represented
      # by <tt>self</tt>.
      #
      # If <tt>self</tt> does not contain a numeric value, <tt>nil</tt> is returned.
      #
      # If <tt>self</tt> contains a numeric value, but no unit or per unit, just
      # the numeric value is returned
      #
      def to_quantity
        return nil unless has_numeric_value?
        if (unit.is_a? Quantify::Unit::Base) && (per_unit.is_a? Quantify::Unit::Base)
          quantity_unit = unit/per_unit
        elsif unit.is_a? Quantify::Unit::Base
          quantity_unit = unit
        elsif per_unit.is_a? Quantify::Unit::Base
          quantity_unit = 1/per_unit
        else
          return value
        end
        Quantity.new(value,quantity_unit)
      end
      alias :to_q :to_quantity

      # Returns a string representation of term based on the term value and any
      # units which are defined. The format of the unit representation follows
      # that defined by <tt>format</tt>, which should represent any of the formats
      # supported by the <i>Quantify::Unit::Base</tt> class (i.e. :name,
      # :pluralized_name, :symbol and :label). Default behaviour uses the unit
      # symbol atribute, i.e. if no format explcitly specified:
      #
      #   my_term.to_s                      #=> "12345 ton"
      #
      #   my_term.to_s :symbol              #=> "12345 ton"
      #
      #   my_term.to_s :name                #=> "12345 short ton"
      #
      #   my_term.to_s :pluralized_name     #=> "12345 tons"
      #
      #   my_term.to_s :label               #=> "12345 ton_us"
      #
      def to_s(format=:symbol)
        if has_numeric_value? && (unit || per_unit)
          self.to_quantity.to_s(format)
        else
          "#{value}"
        end
      end

      # Checks that the units included in <tt>units</tt> are dimensionally
      # equivalent, that is, that they represent the same physucal quantity
      #
      def self.validate_dimensional_equivalence?(*units)
        unless [units].flatten.all? {|unit| unit.dimensions == units[0].dimensions }
          raise AMEE::DataAbstraction::Exceptions::InvalidUnits,
            "The specified term units are not of equivalent dimensions: #{units.map(&:label).join(",")}"
        end
      end
      
      def self.convert_value_to_type(value, type)
        return nil if value.blank?
        type = type.downcase.to_sym if type.is_a?(String)
        
        case type
          when :string    then value.to_s
          when :text      then value.to_s
          when :integer   then value.to_i rescue 0
          when :fixnum    then value.to_i rescue 0
          when :float     then value.to_f rescue 0
          when :decimal   then value.to_s.to_d rescue 0
          when :double    then value.to_s.to_d rescue 0
          when :datetime  then DateTime.parse(value.to_s) rescue nil
          when :time      then Time.parse(value.to_s) rescue nil
          when :date      then Date.parse(value.to_s) rescue nil
          else value
        end
      end
      
    end
  end
end