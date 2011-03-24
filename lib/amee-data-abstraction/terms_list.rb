module AMEE
  module DataAbstraction
    class TermsList < Array
      TermClasses= [:profiles,:drills,:inputs,:outputs,:metadata]
      TermClasses.each do |term|
        define_method(term) do
          TermsList.new select{|x|x.is_a? term.to_s.singularize.classify.constantize}
        end
      end
      TermFlags=[:set,:unset,:visible,:hidden,:fixed]
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
      Selectors=TermClasses+TermFlags+[:before,:after]

      TermProperties=[:label,:name,:path,:value]
      TermProperties.each do |term|
        define_method(term.to_s.pluralize.to_sym) do
          map{|x|x.send(term)}
        end
      end
    end
  end
end
