# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

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

