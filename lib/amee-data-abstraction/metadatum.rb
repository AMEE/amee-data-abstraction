# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: AMEE::DataAbstraction::Metadatum

module AMEE
  module DataAbstraction
    
    # Subclass of <tt>Input</tt> providing methods and attributes appropriate for
    # representing arbitrary metadata which does not correspond to any AMEE profile
    # item value or drill.
    #
    class Metadatum < Input

      # Initialization of <i>Metadatum</i> objects follows that of the parent
      # <i>Input</i> class. The <tt>interface</tt> attribute of <tt>self</tt> is
      # set to <tt>:drop_down</tt> by default, but can be manually configured if
      # required.
      #
      def initialize(options={},&block)
        super
        interface :drop_down unless interface
      end

      # Represents a list of acceptable choices for the value of <tt>self</tt>.
      # Set the list of choices by passing an argument. Retrieve the choices by
      # calling without an argument, e.g.,
      #
      #  my_metadatum.choices 'London', 'New York', 'Tokyo'
      #
      #  my_metadatum.choices                 #=> [ 'London',
      #                                             'New York',
      #                                             'Tokyo' ]
      #
      # A single value of <tt>nil</tt> represents an unrestricted value
      # .
      attr_property :choices

      # Returns <tt>false</tt> as all metadatum are arbitrarily defined and
      # therefore not directly involved in any AMEE calculation.
      #
      def compulsory?(usage=nil)
        false
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
