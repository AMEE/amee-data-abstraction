
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
# :title: Class: AMEE::DataAbstraction::Drill


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
# :title: Class: AMEE::DataAbstraction::Drill

module AMEE
  module DataAbstraction

    # Subclass of <tt>Input</tt> providing methods and attributes appropriate for
    # representing AMEE drill down choices and selections specifically
    #
    class Drill < Input

      public

      # Returns <tt>true</tt> if the UI element of <tt>self</tt> is disabled.
      # Otherwise, returns <tt>false</tt>.
      #
      # A drill is considered disabled if it either (1) explicitly set using the
      # <tt>#disable!</tt> method; (2) has a <i>fixed</i> value; or (3) is not the
      # next drill (because drill should be chosen in order).
      #
      def disabled?
        super || (!set? && !next?)
      end

      # Initialization of <i>Drill</i> objects follows that of the parent
      # <i>Input</i> class. The <tt>interface</tt> attribute of <tt>self</tt> is
      # set to <tt>:drop_down</tt> by default for <tt>Drill</tt> instances, but
      # can be manually configured if required.
      #
      def initialize(options={},&block)
        interface :drop_down
        super
        choice_validation_message
      end

      private

      # Returns <tt>true</tt> if the value set for <tt>self</tt> is one of the
      # available choices. Otherwise, returns <tt>false</tt>.
      #
      def valid?
        super && (choices.include? value)
      end

      # Returns the list of available choices for <tt>self</tt>.
      def choices
        c=parent.amee_drill(:before=>label).choices
        c.length==1 ? [value] : c #Intention is to get autodrilled, drill will result in a UID
      end

      # Returns <tt>true</tt> if <tt>self</tt> is the "first unset" drill, i.e.
      # the one which should be set next
      #
      def next?
        unset? && parent.drills.before(label).all?(&:set?)
      end

    end
  end
end

