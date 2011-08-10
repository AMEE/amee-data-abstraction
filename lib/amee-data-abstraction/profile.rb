
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
# :title: Class: AMEE::DataAbstraction::Profile

module AMEE
  module DataAbstraction

    # Subclass of <tt>Input</tt> providing methods and attributes appropriate for
    # representing AMEE profile item values specifically
    #
    class Profile < Input
      
      # Represents a list of acceptable choices for the value of <tt>self</tt>. 
      # Set the list of choices by passing an argument. Retrieve the choices by 
      # calling without an argument, e.g.,
      #
      #  my_term.choices 'industrial', 'commercial', 'residential'
      #
      #  my_term.choices                      #=> [ 'industrial',
      #                                             'commercial', 
      #                                             'residential' ]
      #  
      # A single value of <tt>nil</tt> represents an unrestricted value
      # .
      attr_property :choices

      # Initialization of <i>Input</i> objects follows that of the parent
      # <i>Term</i> class. The <tt>interface</tt> attribute of <tt>self</tt> is
      # set to <tt>:drop_down</tt> by default if a list of choices is defined
      # using the <tt>choices</tt> attribute. Otherwise the <tt>interface</tt>
      # attribute is set to <tt>:test_box</tt>, but can be manually configured if
      # required.
      #
      def initialize(options={},&block)
        super
        interface :drop_down unless choices.blank?
        choice_validation_message unless choices.blank?
        interface :text_box unless interface
      end

      # Return <tt>true</tt> if the value of <tt>self</tt> is NOT required before
      # the parent calculation can be calculated. Otherwise, return <tt>false</tt>.
      #
      # If no argument is provided, optional status is determined according to the
      # current usage of the parent calculation. Optionality can be determined for
      # a specific usage by passing in the usage path as an argument
      #
      def optional?(usage=nil)
        usage||=parent.current_usage
        usage ? amee_ivd.optional?(usage) : super()
      end

      # Return <tt>true</tt> if the value of <tt>self</tt> is required before
      # the parent calculation can be calculated. Otherwise, return <tt>false</tt>.
      #
      # If no argument is provided, compulsory status is determined according to
      # the current usage of the parent calculation. Compulsory status can be
      # determined for a specific usage by passing in the usage path as an argument
      #
      def compulsory?(usage=nil)
        usage||=parent.current_usage
        usage ? amee_ivd.compulsory?(usage) : super()
      end

      # Return <tt>true</tt> if the value of <tt>self</tt> is either compulsory
      # OR optional in the owning calculation, i.e. is NOT forbidden.
      #
      # If no argument is provided, the optional/compulsory status is defined
      # according to the current usage of the parent caluclation. Otherwise,
      # optional/compulsory status is determined on the basis of the usage whose
      # AMEE platform path matches <tt>usage</tt>
      #
      def in_use?(usage)
        compulsory?(usage)||optional?(usage)
      end

      # Return <tt>true</tt> if the value of <tt>self</tt> is neither compulsory
      # OR optional in the owning calculation, i.e. is forbidden.
      #
      # If no argument is provided, forbbiden status is defined according to the
      # current usage of the parent caluclation. Otherwise, it is determined on
      # the basis of the usage whose AMEE platform path matches <tt>usage</tt>
      #
      def out_of_use?(usage)
        !in_use?(usage)
      end

      # Return the <i>AMEE::Admin::ItemValueDefinition</i> object associated
      # with <tt>self</tt>.
      #
      def amee_ivd
        parent.amee_ivds.detect{|x|x.path==path}
      end

      # Returns <tt>true</tt> if the value set for <tt>self</tt> is valid. If
      # <tt>self</tt> contains neither a custom validation pattern nor any
      # defined choices, <tt>true</tt> is returned. Otherwise, validity depends
      # on the custom validation being successful (if present) and the the value
      # of <tt>self</tt> matching one of the entries in the <tt>choices</tt>
      # attribute (if defined). Otherwise, returns <tt>false</tt>.
      #
      def valid?
        super && (choices.blank? || choices.include?(value))
      end
    end
  end
end
