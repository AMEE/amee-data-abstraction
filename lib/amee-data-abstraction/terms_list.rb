
# Authors::   James Hetherington, James Smith, Andrew Berkeley, George Palmer
# Copyright:: Copyright (c) 2011 AMEE UK Ltd
# License::   Permission is hereby granted, free of charge, to any person obtaining
#             a copy of this software and associated documentation files (the
#             "Software"), to deal in the Software without restriction, including
#             without limitation the rights to use, copy, modify, merge, publish,
#             distribute, sublicense, and/or sell copies of the Software, and to
#             permit persons to whom the Software is furnished to do so, subject
#             to the following conditions:
#
#             The above copyright notice and this permission notice shall be included
#             in all copies or substantial portions of the Software.
#
#             THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#             EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#             MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#             IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#             CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#             TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#             SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# :title: Class: AMEE::DataAbstraction::TermsList

module AMEE
  module DataAbstraction

    # Class extending the <i>Array</i> and providing specific attributes and
    # methods for operating on a collection of instances of the class <i>Term</i>.
    #
    class TermsList < Array

      # Subclasses of the <i>Term</i> class which <tt>self</tt> can contain.
      #
      # Each subclass symbol also represents a dynamically generated method name
      # for <tt>self</tt> which can be called to return a new <tt>TermsList</tt>
      # instance containing that subset of terms only, e.g.,
      # 
      #  my_terms_list.inputs               #=> <AMEE::DataAbstraction::TermsList ... >
      #
      #  my_terms_list.profiles             #=> <AMEE::DataAbstraction::TermsList ... >
      #
      # These methods can be compounded:
      #
      #  my_terms_list.inputs.drills        #=> <AMEE::DataAbstraction::TermsList ... >
      #
      #  my_terms_list.profiles.visible     #=> <AMEE::DataAbstraction::TermsList ... >
      #
      TermClasses= [:profiles,:drills,:inputs,:outputs,:metadata,:usages]

      TermClasses.each do |term|
        define_method(term) do
          self.class.new select{|x|x.is_a? AMEE::DataAbstraction::const_get(term.to_s.singularize.classify)}
        end
      end

      # Boolean attributes of instances of the <i>Term</i> class.
      #
      # Each attribute symbol also represents a dynamically generated method name
      # for <tt>self</tt> which can be called to return a new <tt>TermsList</tt>
      # instance containing that subset of only those terms for which the attribute
      # is true, e.g.,
      #
      #   my_terms_list.visible             #=> <AMEE::DataAbstraction::TermsList ... >
      #
      #   my_terms_list.set                 #=> <AMEE::DataAbstraction::TermsList ... >
      #
      # These methods can be compounded:
      #
      #   my_terms_list.drills.visible.set  #=> <AMEE::DataAbstraction::TermsList ... >
      #
      TermFlags=[:set,:unset,:visible,:hidden,:fixed,
        :optional,:compulsory,:enabled,:disabled,:drop_down,:text_box,:date]

      TermFlags.each do |term|
        define_method(term) do
           self.class.new select{|x|x.send("#{term}?".to_sym)}
        end
      end

      # Return a new <tt>TermsList</tt> instance containing that subset of terms
      # which occur before the term labeled <tt>label</tt> in the owning
      # calculation
      #
      def before(label)
        self.class.new select{|x|x.before?(label)}
      end

      # Return a new <tt>TermsList</tt> instance containing that subset of terms
      # which occur after the term labeled <tt>label</tt> in the owning
      # calculation
      #
      def after(label)
        self.class.new select{|x|x.after?(label)}
      end

      # Return a new <tt>TermsList</tt> instance containing that subset of terms 
      # which are optional in the owning calculation. 
      # 
      # If no argument is provided, the optional status of each term is defined 
      # according to the current usage of the parent caluclation. Otherwise, 
      # optional status is determined on the basis of the usage whose AMEE 
      # platform path matches <tt>usage</tt>
      #
      def optional(usage=nil)
        self.class.new select{|x|x.optional?(usage)}
      end

      # Return a new <tt>TermsList</tt> instance containing that subset of terms
      # which are compulsory in the owning calculation.
      #
      # If no argument is provided, the compulsory status of each term is defined
      # according to the current usage of the parent caluclation. Otherwise,
      # compulsory status is determined on the basis of the usage whose AMEE
      # platform path matches <tt>usage</tt>
      #
      def compulsory(usage=nil)
        self.class.new select{|x|x.compulsory?(usage)}
      end

      # Return a new <tt>TermsList</tt> instance containing that subset of terms
      # which are either compulsory OR optional in the owning calculation, i.e.
      # any which are NOT forbidden.
      #
      # If no argument is provided, the optional/compulsory status of each term
      # is defined according to the current usage of the parent caluclation.
      # Otherwise, optional/compulsory status is determined on the basis of the
      # usage whose AMEE platform path matches <tt>usage</tt>
      #
      def in_use(usage=nil)
        self.class.new select{|x|x.in_use?(usage)}
      end

      # Return a new <tt>TermsList</tt> instance containing that subset of terms
      # which are neither compulsory OR optional in the owning calculation, i.e.
      # those which are forbidden.
      #
      # If no argument is provided, the forbidden status of each term is defined
      # according to the current usage of the parent caluclation. Otherwise,
      # forbidden status is determined on the basis of the usage whose AMEE
      # platform path matches <tt>usage</tt>
      #
      def out_of_use(usage=nil)
        self.class.new select{|x|x.out_of_use?(usage)}
      end
      
      Selectors=TermClasses+TermFlags+[:before,:after,:optional,
        :compulsory,:in_use,:out_of_use]

      # Attributes of the class <i>Term</tt>.
      # 
      # Each attribute symbol also defines a dynamically generated method which
      # return arrays of the values of the named attribute for all terms, e.g.,
      # 
      #   my_terms_list.labels => [ :type, :fuel, :distance, :co2 ... ]
      #   
      #   my_terms_list.values => [ 'van;, 'petrol', 500, 25.4 ... ]
      #
      TermProperties=[:label,:name,:path,:value,:unit,:per_unit,:default_unit,:default_per_unit]

      TermProperties.each do |term|
        define_method(term.to_s.pluralize.to_sym) do
          map{|x|x.send(term)}
        end
      end

    end
  end
end
