# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: AMEE::DataAbstraction::CalculationSet

module AMEE
  module DataAbstraction
    
    # The <i>CalculationSet</i> class represents a collection of prototype
    # calculations (of the class <i>ProtptypeCalculation</i>.
    #
    # Prototype calculations are contained within the @calculations instance variable
    # ordered hash. Calculations can be added manually to the @calculations hash or
    # initialized in place using the <tt>#calculation</tt> method which takes an
    # options hash or block for specifying the prototype calculation properties.
    #
    # Typical usage is to initialize the <i>CalculationSet</i> and its daughter
    # prototype calculations together using block syntax, thus:
    #
    #   Calculations = CalculationSet.new {
    #
    #     calculation {
    #       label :electricity
    #       path "/some/path/for/electricity"
    #       ...
    #     }
    #
    #     calculation {
    #       label :transport
    #       path "a/transport/path"
    #       ...
    #     }
    #
    #     ...
    #   }
    #
    class CalculationSet

      # Class variable holding all instantiated calculation sets keyed on the set
      # name.
      #
      @@sets = {}

      # Convenience method for accessing the @@sets class variable
      def self.sets
        @@sets
      end

      # Retrieve a calculation set on the basis of a configuration file name or
      # relatiev/absolute file path. If configuration files are location within
      # the default Rails location under '/config/calculations' then the path and
      # the .rb extenstion can be omitted from the name.
      #
      def self.find(name)
        @@sets[name.to_sym] or load_set(name)
      end

      # Regenerate a configuration lock file assocaited with the master
      # configuration file <tt>name</tt>. Optionally set a custom path for the
      # lock file as <tt>output_path</tt>, otherwise the lock file path and
      # filename will be based upon the master file with the extension .lock.rb.
      #
      def self.regenerate_lock_file(name,output_path=nil)
        set = CalculationSet.find(name)
        set.generate_lock_file(output_path)
      end

      # Find a specific prototype calculation instance without specifying the set
      # to which it belongs.
      #
      def self.find_prototype_calculation(label)
        @@sets.each_pair do |name,set|
          set = find(name)
          return set[label] if set[label]
        end
        return nil
      end

      protected

      # Load a calculation set based on a filename or full path.
      def self.load_set(name)
        CalculationSet.new(name,:file => name) do
          instance_eval(File.open(self.config_path).read)
        end
      end

      DEFFAULT_RAILS_CONFIG_DIR = "config/calculations"

      # Find the config file assocaited with <tt>name</tt>. The method first checks
      # the default Rails configuration location (config/calculations) then the
      # file path described by <tt>name</tt> relative to the Rails root and by
      # absolute path.
      def self.find_config_file(name)
        default_config_dir = defined?(::Rails) ? "#{::Rails.root}/#{DEFFAULT_RAILS_CONFIG_DIR}" : nil
        if defined?(::Rails) && File.exists?("#{default_config_dir}/#{name.to_s}.rb")
          "#{default_config_dir}/#{name.to_s}.rb"
        elsif defined?(::Rails) && File.exists?("#{default_config_dir}/#{name.to_s}")
          "#{default_config_dir}/#{name.to_s}"
        elsif defined?(::Rails) && File.exists?("#{::Rails.root}/#{name}")
          "#{::Rails.root}/#{name}"
        elsif File.exists?(name)
          name
        else
          raise ArgumentError, "The config file '#{name}' could not be located"
        end
      end

      public
      
      attr_accessor :calculations, :name, :file

      # Initialise a new Calculation set. Specify the name of the calculation set 
      # as the first argument. This name is used as the set key within the class
      # variable @@sets hash.
      #
      def initialize(name,options={},&block)
        raise ArgumentError, "Calculation set must have a name" unless name
        @name = name
        @file = CalculationSet.find_config_file(options[:file]) if options[:file]
        @calculations = ActiveSupport::OrderedHash.new
        @all_blocks=[]
        @all_options={}
        instance_eval(&block) if block
        @@sets[@name.to_sym] = self
      end

      # Shorthand method for returning the prototype calculation which is represented
      # by a label matching <tt>sym</tt>
      #
      def [](sym)
        @calculations[sym.to_sym]
      end

      # Instantiate a <i>PrototypeCalculation</i> within this calculation set,
      # initializing with the supplied DSL block to be evaluated in the context
      # of the newly created calculation
      #
      def calculation(options={},&block)
        new_content=PrototypeCalculation.new(options.merge(@all_options),&block)
        @all_blocks.each {|all_block| new_content.instance_eval(&all_block) }
        new_content.name new_content.label.to_s.humanize unless new_content.name
        @calculations[new_content.label]=new_content
      end

      # Append the supplied block to the DSL block of ALL calculations in this
      # calculation set. This is useful for configuration which is required
      # across all calculations (e.g. overriding human readable names or adding
      # globally applicable metadatum)
      #
      def all_calculations(options={},&dsl_block)
        @all_blocks.push dsl_block
        @all_options.merge(options)
      end

      # Instantiate several prototype calculations, by loading each possible usage
      # for the category with path given in <tt>apath</tt>.
      # 
      # Each instantiated calculation is customised on the basis of the supplied
      # DSL block. The usage is given as a parameter to the DSL block
      #
      def calculations_all_usages(apath,options={},&dsl_block)
        dummycalc=PrototypeCalculation.new{path apath}
        dummycalc.amee_usages.each do |usage|
          calculation(options){
            path apath
            instance_exec(usage,&dsl_block)
          }
        end
      end

      # Returns the path to the configuration file for <tt>self</tt>. If a .lock
      # file exists, this takes precedence, otherwise the master config file
      # described by the <tt>#file</tt> attribute is returned.
      #
      def config_path
        lock_file_exists? ? lock_file_path : @file
      end

      # Returns the path to the configuration lock file
      def lock_file_path
        @file.gsub(".rb",".lock.rb") rescue nil
      end

      # Returns <tt>true</tt> if a configuration lock file exists. Otherwise,
      # returns <tt>false</tt>.
      #
      def lock_file_exists?
        File.exists?(lock_file_path)
      end

      # Generates a lock file for the calcuation set configuration. If no argument
      # is provided the, the lock file is generated using the filename and path
      # described by the <tt>#lock_file_path</tt> method. If a custom output
      # location is required, this can be provided optionally as an argument.
      #
      def generate_lock_file(output_path=nil)
        file = output_path || lock_file_path or raise ArgumentError,
          "No path for lock file known. Either set path for the master config file using the #file accessor method or provide as an argument"
        string = ""
        @calculations.values.each do |prototype_calculation|
          string += "calculation {\n\n"
          string += "  name \"#{prototype_calculation.name}\"\n"
          string += "  label :#{prototype_calculation.label}\n"
          string += "  path \"#{prototype_calculation.path}\"\n\n"
          prototype_calculation.terms.each do |term|
            string += "  #{term.class.to_s.split("::").last.downcase} {\n"
            string += "    name \"#{term.name}\"\n" unless term.name.blank?
            string += "    label :#{term.label}\n" unless term.label.blank?
            string += "    path \"#{term.path}\"\n" unless term.path.blank?
            string += "    value \"#{term.value}\"\n" unless term.value.blank?

            if term.is_a?(AMEE::DataAbstraction::Input)
              string += "    fixed \"#{term.value}\"\n" if term.fixed? && !term.value.blank?
              if term.is_a?(AMEE::DataAbstraction::Drill)
                string += "    choices \"#{term.choices.join('\',\'')}\"\n" if term.instance_variable_defined?("@choices")  && !term.choices.blank?
              elsif term.is_a?(AMEE::DataAbstraction::Profile)
                string += "    choices [\"#{term.choices.join('\"','\"')}\"]\n" if term.instance_variable_defined?("@choices")  && !term.choices.blank?
              end
              string += "    optional!\n" if term.optional?
            end

            string += "    default_unit :#{term.default_unit.label}\n" unless term.default_unit.blank?
            string += "    default_per_unit :#{term.default_per_unit.label}\n" unless term.default_per_unit.blank?
            string += "    alternative_units :#{term.alternative_units.map(&:label).join(', :')}\n" unless term.alternative_units.blank?
            string += "    alternative_per_units :#{term.alternative_per_units.map(&:label).join(', :')}\n" unless term.alternative_per_units.blank?
            string += "    unit :#{term.unit.label}\n" unless term.unit.blank?
            string += "    per_unit :#{term.per_unit.label}\n" unless term.per_unit.blank?
            string += "    type :#{term.type}\n" unless term.type.blank?
            string += "    interface :#{term.interface}\n" unless term.interface.blank?
            string += "    note \"#{term.note}\"\n" unless term.note.blank?
            string += "    disable!\n" if !term.is_a?(AMEE::DataAbstraction::Drill) && term.disabled?
            string += "    hide!\n" if term.hidden?
            string += "  }\n\n"
          end
          string += "}\n\n"
        end
        File.open(file,'w') { |f| f.write string }
      end

    end
  end
end