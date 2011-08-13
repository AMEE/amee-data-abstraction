# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: AMEE::DataAbstraction::OngoingCalculation

module AMEE
  module DataAbstraction

    # Instances of the <i>OngoingCalculation</i> class represent actual
    # calculations made via the AMEE platform.
    #
    # The class inherits from the <i>Calculation</i> class and is therefore
    # primarly characterised by the <tt>label</tt>, <tt>name</tt>, and <tt>path</tt>
    # attributes, as well as an associated instance of the <tt>TermsList</tt>
    # class which represents each of the values (input, outputs, metdata) involved
    # in the calculation.
    #
    # Instances of <i>OngoingCalcualtion</i> are typically instantiated from an
    # instance of <i>PrototypeCalculation</i> using the <tt>#begin_calculation</tt>
    # method, e.g.
    #
    #  my_prototype.begin_calculation       #=> <AMEE::DataAbstraction::OngoingCalculation ...>
    #
    # In this case, the new instance inherits all of the attributes and terms
    # defined on the <i>PrototypeCalculation</i> template.
    #
    # In contrast to instances of <i>PrototypeCalculation</i>, instances of the
    # <i>OngoingCalculation</i> class will typically have their term values
    # explicitly set according to the specific calculation scenario being
    # represented. Other term attributes, e.g. units, may also be modified on a
    # calculation-by-calculation basis. These values and other attributes form
    # (at least some of) the data which is passed to the AMEE platform in order
    # to make caluclations.
    #
    class OngoingCalculation < Calculation

      public

      # String representing the AMEE platform profile UID assocaited with <tt>self</tt>
      attr_accessor :profile_uid
      
      # String representing the AMEE platform profile item UID assocaited with <tt>self</tt>
      attr_accessor :profile_item_uid
      
      # Hash of invalidity messages. Keys are represent the labels of terms
      # assocaited with <tt>self</tt>. Values are string error message reports associated
      # with the keyed term.
      #
      attr_accessor :invalidity_messages

      # Construct an Ongoing Calculation. Should be called only via
      # <tt>PrototypeCalculation#begin_calculation</tt>. Not intended for external
      # use.
      #
      def initialize
        super
        dirty!
        reset_invalidity_messages
      end

      # Returns true if the value of a term associated with <tt>self</tt> has been changed
      # since the calculation was last synchronized with the AMEE platform.
      # Otherwise, return false.
      #
      def dirty?
        @dirty
      end

      # Declare that the calculation is dirty, i.e. that changes to term values
      # have been made since <tt>self</tt> was last synchronized with the AMEE platform,
      # in which case a synchonization with with AMEE must occur for <tt>self</tt> to be
      # valid.
      #
      def dirty!
        @dirty=true
      end

      # Declare that the calculation is not dirty, and need not be sent to AMEE
      # for results to be valid.
      #
      def clean!
        @dirty=false
      end

      # Returns true if all compulsory terms are set, i.e. ahve non-nil values.
      # This inidicates that <tt>self</tt> is ready to be sent to the AMEE platform for
      # outputs to be calculated
      #
      def satisfied?
        inputs.compulsory.unset.empty?
      end

      # Mass assignment of (one or more) term attributes (value, unit, per_unit)
      # based on data defined in <tt>choice</tt>. <tt>choice</tt> should be
      # a hash with keys representing the labels of terms which are to be updated.
      # Hash values can represent either the the value to be assigned explicitly,
      # or, alternatively, a hash representing any or all of the term value, unit
      # and per_unit attributes (keyed as :value, :unit and :per_unit).
      #
      # Unit attributes can be represented by any form which is accepted by the
      # <i>Quantify::Unit#for</i> method (either an instance of
      # <i>Quantify::Unit::Base</i> (or subclass) or a symbolized or string
      # representation of the a unit symbol, name or label).
      #
      # Nil values are ignored. Term attributes can be intentionally blanked by
      # passing a blank string as the respective hash value.
      #
      # Examples of options hash which modify only term values:
      #
      #  options = { :type => 'van' }
      #
      #  options = { :type => 'van',
      #              :distance => 100 }
      #
      #  options = { :type => 'van',
      #              :distance => "" }
      #
      # Examples of options hash which modify other term attributes:
      #
      #  options = { :type => 'van',
      #              :distance => { :value => 100 }}
      #
      #  options = { :type => 'van',
      #              :distance => { :value => 100,
      #                             :unit => :mi }}
      #
      #  options = { :type => 'van',
      #              :distance => { :value => 100,
      #                             :unit => 'feet' }}
      #
      #  my_distance_unit = <Quantify::Unit::NonSI:0xb71cac48 @label="mi" ... >
      #  my_time_unit     = <Quantify::Unit::NonSI:0xb71c67b0 @label="h" ... >
      #
      #  options = { :type => 'van',
      #              :distance => { :value => 100,
      #                             :unit => my_unit,
      #                             :per_unit => my_time_unit }}
      #
      #  my_calculation.choose_without_validation!(options)
      #
      # Do not attempt to check that the values specified are acceptable.
      #
      def choose_without_validation!(choice)
        # Make sure choice keys are symbols since they are mapped to term labels
        # Uses extension methods for Hash defined in /core_extensions
        choice.recursive_symbolize_keys!

        new_profile_uid= choice.delete(:profile_uid)
        self.profile_uid=new_profile_uid if new_profile_uid
        new_profile_item_uid= choice.delete(:profile_item_uid)
        self.profile_item_uid=new_profile_item_uid if new_profile_item_uid
        choice.each do |k,v|
          next unless self[k]
          if v.is_a? Hash
            # <tt>if has_key?</tt> clause included so that single attributes can
            # be updated without nullifying others if their values are not
            # explicitly passed. Intentional blanking of values is enabled by
            # passing nil or "".
            #
            self[k].value v[:value] if v.has_key?(:value)
            self[k].unit v[:unit] if v.has_key?(:unit)
            self[k].per_unit v[:per_unit] if v.has_key?(:per_unit)
          else
            self[k].value v
          end
        end
      end

      # Similar to <tt>#choose_without_validation!</tt> but performs validation
      # on the modified input terms and raises a <i>ChoiceValidation</i>
      # exception if any of the values supplied is invalid
      #
      def choose!(choice)
        choose_without_validation!(choice)
        validate!
        raise AMEE::DataAbstraction::Exceptions::ChoiceValidation.new(invalidity_messages) unless
          invalidity_messages.empty?
      end

      # Similar to <tt>#choose!</tt> but returns <tt>false</tt> if any term
      # attributes are invalid, rather than raising an exception. Returns
      # <tt>true</tt> if validation is successful.
      #
      def choose(choice)
        begin
          choose!(choice)
          return true
        rescue AMEE::DataAbstraction::Exceptions::ChoiceValidation
          return false
        end
      end

      # Synchonizes the current term values and attributes with the AMEE platform
      # if <tt>self</tt> is <tt>dirty?</tt>, and subsequently calls <tt>clean!</tt>
      # on <tt>self</tt>
      #
      def calculate!
        return unless dirty?
        syncronize_with_amee
        clean!
      end

      # Check that the values set for all terms are acceptable, and raise a
      # <i>ChoiceValidation</i> exception if not. Error messages are available
      # via the <tt>self.invalidity_messages</tt> hash.
      #
      def validate!
        return unless dirty?
        reset_invalidity_messages
        inputs.each do |d|
          d.validate! unless d.unset?
        end
        autodrill
      end

      # Declare that the term labelled by <tt>label</tt> has an unnaceptable value
      # and load the <tt>message</tt> into the <tt>invalidity_messages</tt> hash.
      #
      def invalid(label,message)
        @invalidity_messages[label]=message
      end

      # Set the values of any invalid terms to nil. Can be called following any
      # of the <tt>#choose...</tt> methods so that invalid terms resulting from
      # modification of a previously valid calculation can be cleared. This is
      # particularly useful in cases where drill down choices have been changed
      # thus invalidating the choices for subsequent drills.
      #
      def clear_invalid_terms!
        terms.select do |term|
          invalidity_messages.keys.include?(term.label)
        end.each do |term|
          term.value nil
        end
        reset_invalidity_messages
      end

      private

      # Empty the hash of error messages for term choices.
      def reset_invalidity_messages
        @invalidity_messages={}
      end

      # Obtain from the AMEE platform the results of a calculation, and set these
      # to the output terms of <tt>self</tt>.
      #
      def load_outputs
        outputs.each do |output|
          res=nil
          if output.path==:default
            res= profile_item.amounts.find{|x| x[:default] == true}
          else
            res= profile_item.amounts.find{|x| x[:type] == output.path}
          end
          if res
            output.value res[:value]
            output.unit res[:unit]
            output.per_unit res[:per_unit]
          else
            # If no platform result, then no outputs should be set. Added so that
            # nullifying a compulsory PIV wipes output value, otherwise previous
            # output values persist after PIVs have been removed.
            #
            output.value nil
          end
        end
      end

      # Load any metadata stored in the AMEE profile which can be used to set
      # metadata for <tt>self</tt>. Not implemented in AMEE yet.
      #
      def load_metadata  
      end

      # If a profile item exists for <tt>self</tt>, load the corresponding values
      # and units for any unset <i>Profile</i> terms (profile item values) from
      # the AMEE platform
      #
      def load_profile_item_values  
        return unless profile_item
        profiles.unset.each do |term|
          ameeval=profile_item.values.find { |value| value[:path] == term.path }
          term.value ameeval[:value]
          term.unit ameeval[:unit]
          term.per_unit ameeval[:per_unit]
        end
      end

      # Load drill values from the AMEE platform. If the remote drills selections
      # are different than locally set values, raise a <i>Syncronization</i>
      # exception.
      #
      # If an exception is raised, typical practice would be to delete the profile
      # item associated with <tt>self</tt> and create a new one with the current
      # selection of drill down choices (see, for example, the
      # <tt>#synchronize_with_amee</tt> method
      #
      def load_drills
        return unless profile_item
        drills.each do |term|
          ameeval=data_item.value(term.path)
          raise Exceptions::Syncronization if term.set? && ameeval!=term.value
          term.value ameeval
        end
      end

      # Dispatch the calculation to AMEE. If necessary, delete an out of date
      # AMEE profile item and create a new one. Fetch any values which are stored
      # in the AMEE platform and not stored locally. Send any values stored locally
      # and not stored in the AMEE platform. Fetch calculation results from the
      # AMEE platform and update outputs assocaited with <tt>self</tt>
      #
      def syncronize_with_amee
        new_memoize_pass
        find_profile
        load_profile_item_values
        begin
          load_drills
        rescue Exceptions::Syncronization
          delete_profile_item
        end
        load_metadata
        # We could create an unsatisfied PI, and just check drilled? here
        if satisfied?
          if profile_item
            set_profile_item_values
          else
            create_profile_item
          end
          load_outputs
        end
      rescue AMEE::UnknownError
        # Tidy up, only if we created a "Bad" profile item.
        # Need to check this condition
        delete_profile_item
        raise DidNotCreateProfileItem
      end

      # Returns a <i>String</i> representation of drill down choices appropriate for
      # submitting to the AMEE platform. An optional hash argument can be provided,
      # with the key <tt>:before</tt> in order to specify the drill down choice
      # to which the representation is required, e.g.
      #
      #  my_calc.drill_options                     #=> "type=van&fuel=petrol&size=2.0+litres"
      #
      #  my_calc.drill_options(:before => :size)   #=> "type=van&fuel=petrol"
      #
      def drill_options(options={})
        to=options.delete(:before)
        drills_to_use=to ? drills.before(to).set : drills.set
        drills_to_use.map{|x| "#{CGI.escape(x.path)}=#{CGI.escape(x.value)}"}.join("&")
      end

      # Returns a <i>Hash</i> representation of <i>Profile</i> term attributes
      # appropriate for submitting to the AMEE platform via the AMEE rubygem.
      #
      def profile_options
        result={}
        profiles.set.each do |piv|
          result[piv.path]=piv.value
          result["#{piv.path}Unit"]=piv.unit.label unless piv.unit.nil?
          result["#{piv.path}PerUnit"]=piv.per_unit.label unless piv.per_unit.nil?
        end
        if contents[:start_date] && !contents[:start_date].value.blank?
          result[:start_date] = contents[:start_date].value
        end
        if contents[:end_date] && !contents[:end_date].value.blank?
          result[:end_date] = contents[:end_date].value
        end
        return result
      end

      # Returns a <i>Hash</i> of options for profile item GET requests to the AMEE
      # platform.
      #
      # This is where is where return unit convertion requests can be handled
      # if/when theseare implemented.
      #
      def get_options
        # Specify unit options here based on the contents
        # getopts={}
        # getopts[:returnUnit] = params[:unit] if params[:unit]
        # getopts[:returnPerUnit] = params[:perUnit] if params[:perUnit]
        return {}
      end

      # Return the <i>AMEE::Profile::Profile</i> object under which the AMEE profile
      # item associated with <tt>self</tt> belongs and and update
      # <tt>self.profile_uid</tt> to make the appropriate reference.
      #
      def find_profile
        unless self.profile_uid
          prof ||= AMEE::Profile::ProfileList.new(connection).first
          prof ||= AMEE::Profile::Profile.create(connection)
          self.profile_uid=prof.uid
        end
      end

      # Generate a unique name for the profile item assocaited with <tt>self</tt>.
      # This is required in order to make similarly drilled profile items within 
      # the same profile distinguishable. 
      # 
      # This is random at present but could be improved to generate more meaningful
      # name by interrogating metadata according to specifications of an
      # organisational model.
      #
      def amee_name
        UUIDTools::UUID.timestamp_create
      end


      # Create a profile item in the AMEE platform to be associated with
      # <tt>self</tt>. Raises <i>AlreadyHaveProfileItem</i> exception if a
      # profile item value is already associated with <tt>self</tt>
      #
      def create_profile_item
        raise Exceptions::AlreadyHaveProfileItem unless profile_item_uid.blank?
        location = AMEE::Profile::Item.create(profile_category,
          # call <tt>#data_item_uid</tt> on drill object rather than <tt>self</tt> 
          # since there exists no profile item value yet
          amee_drill.data_item_uid,
          profile_options.merge(:get_item=>false,:name=>amee_name))
        self.profile_item_uid=location.split('/').last
      end

      # Methods which should be memoized once per interaction with AMEE to minimise
      # API calls. These require wiping at every pass, because otherwise, they might
      # change, e.g. if metadata changes change the profile
      #
      MemoizedProfileInformation=[:profile_item,:data_item,:profile_category]

      # Clear the memoized values.
      def new_memoize_pass
        MemoizedProfileInformation.each do |prop|
          instance_variable_set("@#{prop.to_s}",nil)
        end
      end

      # Return the <i>AMEE::Profile::Item</i> object associated with self. If
      # not set, instantiates via the AMEE platform and assigns to <tt>self</tt>
      #
      def profile_item
        @profile_item||=AMEE::Profile::Item.get(connection, profile_item_path, get_options) unless profile_item_uid.blank?
      end

      # Update the associated profile item in the AMEE platform with the current
      # <i>Profile</i> term values and attributes
      #
      def set_profile_item_values
        AMEE::Profile::Item.update(connection,profile_item_path, 
          profile_options.merge(:get_item=>false))
        #Clear the memoised profile item, to reload with updated values
        @profile_item=nil
      end

      # Delete the profile item which is associated with <tt>self</tt> from the
      # AMEE platform and nullify the local references (i.e.
      # <tt>@profile_item</tt> and <tt>#profile_item_uid</tt>)
      #
      def delete_profile_item
        AMEE::Profile::Item.delete(connection,profile_item_path)
        self.profile_item_uid=false
        @profile_item=nil
      end

      # Returns a string representing the AMEE platform path to the profile
      # category associated with <tt>self</self>
      #
      def profile_category_path
        "/profiles/#{profile_uid}#{path}"
      end

      # Returns a string representing the AMEE platform path to the profile
      # item associated with <tt>self</self>
      #
      def profile_item_path
        "#{profile_category_path}/#{profile_item_uid}"
      end

      # Returns a string representing the AMEE platform path to the data item
      # associated with <tt>self</self>
      #
      def data_item_path
        "/data#{path}/#{data_item_uid}"
      end

      # Returns a string representing the AMEE platform UID for the data item
      # associated with <tt>self</self>
      #
      def data_item_uid
        profile_item.data_item_uid
      end

      # Return the <i>AMEE::Data::Item</i> object associated with self. If
      # not set, instantiates via the AMEE platform and assigns to <tt>self</tt>
      #
      def data_item
        @data_item||=AMEE::Data::Item.get(connection, data_item_path, get_options)
      end

      # Return the <i>AMEE::Profile::Category</i> object associated with self. If
      # not set, instantiates via the AMEE platform and assigns to <tt>self</tt>
      #
      def profile_category
        @profile_category||=AMEE::Profile::Category.get(connection, profile_category_path)
      end

      # Automatically set the value of a drill term if there is only one choice
      def autodrill
        
        picks=amee_drill.selections
        picks.each do |path,value|
          # If drill term does not exist, initialize a dummy instance.
          # 
          # This is useful in those cases where some drills selections are unecessary
          # (i.e. not all choices require selection for data items to be uniquely
          # identified) and removes the need to explicitly specify the blank drills
          # in configuration. This doesn't matter if calculations are auto configured.
          #
          if drill = drill_by_path(path)
            drill.value value
          else
            drills << Drill.new {path path; value value}
          end
        end
      end

      public

      # Instantiate an <tt>AMEE::Data::DrillDown</tt> object representing the
      # drill down sequence defined by the drill terms associated with
      # <tt>self</tt>. As with <tt>#drill_options</tt>, An optional hash argument
      # can be provided, with the key <tt>:before</tt> in order to specify the
      # drill down choice to which the representation is required, e.g.
      #
      #  my_calc.amee_drill(:before => :size)
      #
      def amee_drill(options={})
        AMEE::Data::DrillDown.get(connection,"/data#{path}/drill?#{drill_options(options)}")
      end

    end
  end
end
