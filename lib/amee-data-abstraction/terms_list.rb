module AMEE
  module DataAbstraction
    class TermsList < Array
      TermClasses= [:profiles,:drills,:inputs,:outputs,:metadata,:usages]
      TermClasses.each do |term|
        define_method(term) do
          TermsList.new select{|x|x.is_a? AMEE::DataAbstraction::const_get(term.to_s.singularize.classify)}
        end
      end
      TermFlags=[:set,:unset,:visible,:hidden,:fixed,:optional,:compulsory,:enabled,:disabled]
      TermFlags.each do |term|
        define_method(term) do
           TermsList.new select{|x|x.send("#{term}?".to_sym)}
        end
      end
      def before(label)
        res=TermsList.new select{|x|x.before?(label)}
        return res
      end
      def after(label)
        TermsList.new select{|x|x.after?(label)}
      end
      def optional(usage=nil)
        TermsList.new select{|x|x.optional?(usage)}
      end
      def compulsory(usage=nil)
        TermsList.new select{|x|x.compulsory?(usage)}
      end
      def in_use(usage=nil)
        TermsList.new select{|x|x.in_use?(usage)}
      end
      def out_of_use(usage=nil)
        TermsList.new select{|x|x.out_of_use?(usage)}
      end
      
      Selectors=TermClasses+TermFlags+[:before,:after,:optional,
        :compulsory,:in_use,:out_of_use]

      TermProperties=[:label,:name,:path,:value]
      TermProperties.each do |term|
        define_method(term.to_s.pluralize.to_sym) do
          map{|x|x.send(term)}
        end
      end
    end
  end
end
