# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: AMEE::DataAbstraction::Usage

module AMEE
  module DataAbstraction
    
    # Subclass of <tt>Input</tt> providing methods and attributes appropriate for
    # representing adjustable calculation usages specifically.
    # 
    # Only one instance of <i>Usage</i> can be assocaited with a particular
    # calucaltion object. When the value of <tt>self</tt> is changed, profile
    # item value terms which are forbidden in the new usage will be inactivated
    # and optional/compulsory flags are set on the remaining terms.
    #
    class Usage < Input

      # Initialization of <i>Usage</i> objects follows that of the parent
      # <i>Input</i> class, with a number of differences.
      #
      # If the parent caluclation already contains a usage term, a <i>TwoUsages</i>
      # exception is raised.
      #
      # The <tt>label<tt> attribute is set by default to <tt>:usage</tt>.
      #
      # The <tt>interface</tt> attribute of <tt>self</tt> is set to
      # <tt>:drop_down</tt> by default, but can be manually configured if
      # required.
      #
      # The <tt>inactive</tt> property of <tt>self</tt> is set to <tt>:invisible</tt>
      # by default.
      #
      def initialize(options={},&block)
        raise Exceptions::TwoUsages if options[:parent].current_usage
        label :usage
        @inactive=:invisible
        super
        interface :drop_down unless interface
      end

      # Represents the method of handling forbidden terms. Should they be hidden
      # in generated UIs or just disabled (greyed out)? Set the behaviour by
      # passing either <tt>:invisible</tt> or <tt>:disabled</tt> as an argument. 
      # Retrieve the defined behaviour by calling without an argument.
      #
      attr_property :inactive

      # Adjust the value of <tt>self</tt> indicating that a new usage should be
      # switch to in the parent caluclation. This method has the effect of
      # (de)activating terms in the parent calculation as appropriate.
      #
      def value(*args)
        unless args.empty?
          @value=args.first
          activate_selected(value)
        end
        super
      end

      # Activate and deactivate terms in the parent calculation according to the
      # compulsory/optional/forbidden status' of each in the usage indicated by
      # <tt>usage</tt>
      #
      def activate_selected(usage=nil)
        parent.profiles.in_use(usage).each do |term|
          case @inactive
          when :invisible
            term.show!
          when :disabled
            term.enable!
          end
        end
        parent.profiles.out_of_use(usage).each do |term|
          case @inactive
          when :invisible
            term.hide!
          when :disabled
            term.disable!
          end
        end
      end

      # Returns an array of available valid values for <tt>self</tt>.
      def choices
        parent.amee_usages
      end
    end
  end
end
