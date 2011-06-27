module AMEE
  module DataAbstraction
    # Syntactic sugar over an array of terms.
    class TermsList < Array

      # Subclasses of term which this class can contain
      # Methods are generated to select out each of these subsets from an array
      # e.g. myarray.inputs
      TermClasses= [:profiles,:drills,:inputs,:outputs,:metadata,:usages]

      TermClasses.each do |term|
        define_method(term) do
          self.class.new select{|x|x.is_a? AMEE::DataAbstraction::const_get(term.to_s.singularize.classify)}
        end
      end

      # Selectors on term which this class can contain
      # Methods are generated to select out each of these subsets from an array
      # e.g. myarray.set, myarray.visible etc...
      TermFlags=[:set,:unset,:visible,:hidden,:fixed,
        :optional,:compulsory,:enabled,:disabled,:drop_down,:text_box,:date]

      TermFlags.each do |term|
        define_method(term) do
           self.class.new select{|x|x.send("#{term}?".to_sym)}
        end
      end

      # Return a TermsList of that subset of the terms which occur after the given label
      # in the owning calculation
      def before(label)
        self.class.new select{|x|x.before?(label)}
      end

      # Return a TermsList of that subset of the terms which occur after the one with the given label
      # in the owning calculation
      def after(label)
        self.class.new select{|x|x.after?(label)}
      end

      # Return a TermsList of that subset of the terms which are optional in the supplied usage
      def optional(usage=nil)
        self.class.new select{|x|x.optional?(usage)}
      end

      # Return a TermsList of that subset of the terms which are compulsory in the supplied usage
      def compulsory(usage=nil)
        self.class.new select{|x|x.compulsory?(usage)}
      end

      # Return a TermsList of that subset of the terms which are not forbidden in the supplied usage
      def in_use(usage=nil)
        self.class.new select{|x|x.in_use?(usage)}
      end

      # Return a TermsList of that subset of the terms which are forbidden in the supplied usage
      def out_of_use(usage=nil)
        self.class.new select{|x|x.out_of_use?(usage)}
      end
      
      Selectors=TermClasses+TermFlags+[:before,:after,:optional,
        :compulsory,:in_use,:out_of_use]

      # Properties of terms. Methods are generated which return an array of the values of this property
      # on all terms
      # e.g. myarray.labels => [:termlabel1,:termlabel2...]
      TermProperties=[:label,:name,:path,:value,:unit,:per_unit,:default_unit,:default_per_unit]

      TermProperties.each do |term|
        define_method(term.to_s.pluralize.to_sym) do
          map{|x|x.send(term)}
        end
      end

    end
  end
end
