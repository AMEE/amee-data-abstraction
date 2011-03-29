module AMEE
  module DataAbstraction
    class Usage < Input
      def initialize(options={},&block)
        raise Exceptions::TwoUsages if options[:parent].current_usage
        label :usage
        @inactive=:invisible
        super
        interface :drop_down unless interface
      end
      attr_property :inactive
      def value(*args)
        unless args.empty?
          @value=args.first
          activate_selected(value)
        end
        return @value
      end
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
      def choices
        parent.amee_usages
      end
    end
  end
end
