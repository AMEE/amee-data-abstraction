module AMEE
  module DataAbstraction
    # Term representing an adjustable usage
    # When the value is changed, profile item value terms will be inactivated which
    # are forbidden in the relevant usage, and optional/compulsory flags will be set on the terms.
    class Usage < Input
      def initialize(options={},&block)
        raise Exceptions::TwoUsages if options[:parent].current_usage
        label :usage
        @inactive=:invisible
        super
        interface :drop_down unless interface
      end

      #When a term is forbidden in a usage, should it be hidden in generated UIs,
      #or just disabled (greyed out)? Choose either :invisible or :disabled.
      attr_property :inactive

      # Adjust the value, and then inactivate terms in the parent calculation as appropriate.
      def value(*args)
        unless args.empty?
          @value=args.first
          activate_selected(value)
        end
        return @value
      end

      # Inactivate terms in the parent calculation as appropriate to the supplied usage
      def activate_selected(usage=nil)
        parent.profiles.in_use(usage).each do |term|
          case @inactive
          when :invisible
            term.show!
          when :disabled
            term.ensable!
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

      # Get array of available values for the usage
      def choices
        parent.amee_usages
      end
    end
  end
end
