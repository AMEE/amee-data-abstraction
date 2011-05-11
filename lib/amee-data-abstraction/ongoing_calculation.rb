module AMEE
  module DataAbstraction
    class OngoingCalculation < Calculation

      public


      def choose!(choice)   
        choose_without_validation!(choice)
        validate!
        raise AMEE::DataAbstraction::Exceptions::ChoiceValidation.new(invalidity_messages) unless invalidity_messages.empty?
      end

      def choose(choice)
        begin
          choose!(choice)
          return true
        rescue AMEE::DataAbstraction::Exceptions::ChoiceValidation
          return false
        end
      end

      def calculate!
        return unless dirty?
        syncronize_with_amee
        clean!
      end

      def clear_invalid_terms!
        terms.select do |term|
          invalidity_messages.keys.include?(term.label)
        end.each do |term|
          term.value nil
        end
        reset_invalidity_messages
      end

      # Friend constructor for PrototypeCalculation ONLY
      def initialize
        super
        dirty!
        reset_invalidity_messages
      end

      def satisfied?
        inputs.compulsory.unset.empty?
      end

      attr_accessor :profile_uid,:profile_item_uid,:invalidity_messages

      def dirty?
        @dirty
      end

      def dirty!
        @dirty=true
      end

      def clean!
        @dirty=false
      end

      #protected#--- not public API - only persistence gem should call these two

      def validate!
        reset_invalidity_messages
        inputs.each do |d|
          d.validate! unless d.unset?
        end

        autodrill
      end

      def invalid(label,message)
        @invalidity_messages[label]=message
      end

      def choose_without_validation!(choice)
        new_profile_uid= choice.delete(:profile_uid)
        self.profile_uid=new_profile_uid if new_profile_uid
        new_profile_item_uid= choice.delete(:profile_item_uid)
        self.profile_item_uid=new_profile_item_uid if new_profile_item_uid
        choice.each do |k,v|
          next unless self[k]
          unless v.blank?
            unless v.is_a? Hash
              self[k].value v unless v.blank?
            else
              self[k].value v[:value]
              self[k].unit v[:unit]
              self[k].per_unit v[:per_unit]
            end
          end
        end
      end

      private

      def reset_invalidity_messages
        @invalidity_messages={}
      end

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
          end
        end
      end

      def load_metadata
        # Load any metadata stored in the AMEE profile which can be used to
        # set the metadata for this calculation
      end

      def load_profile_item_values
        # For any unset profile item values, load the corresponding values from
        # amee, if we have been given a profile uid
        return unless profile_item
        profiles.unset.each do |term|
          ameeval=profile_item.values.find { |value| value[:path] == term.path }
          term.value ameeval[:value]
          term.unit ameeval[:unit]
          term.per_unit ameeval[:per_unit]
        end
      end

      def load_drills
        return unless profile_item
        drills.each do |term|
          ameeval=data_item.value(term.path)
          # Inconsistent drills would mean we'd need to delete the PI and start again
          # Need to think about how to handle this.
          raise Exceptions::Syncronization if term.set? && ameeval!=term.value
          term.value ameeval
        end
      end

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
        if satisfied? # We could create an unsatisfied PI, and just check drilled? here
          if profile_item
            set_profile_item_values
          else
            create_profile_item
          end
          load_outputs
        end
      rescue AMEE::UnknownError
        # Tidy up, only if we created a "Bad" profile item. Need to check this condition
        delete_profile_item
        raise DidNotCreateProfileItem
      end
      
      def drill_options(options={})
        to=options.delete(:before)
        drills_to_use=to ? drills.before(to).set : drills.set
        drills_to_use.map{|x| "#{CGI.escape(x.path)}=#{CGI.escape(x.value)}"}.join("&")
      end

      def profile_options
        result={}
        profiles.set.each do |piv|
          result[piv.path]=piv.value
          result["#{piv.path}Unit"]=piv.unit.label unless piv.unit.nil?
          result["#{piv.path}PerUnit"]=piv.per_unit.label unless piv.per_unit.nil?
        end
        if contents[:start_date] and not contents[:start_date].value.blank?
          result[:start_date]=Date.parse contents[:start_date].value
        end
        if contents[:end_date] and not contents[:end_date].value.blank?
          result[:end_date]=Date.parse contents[:end_date].value
        end
        return result
      end
      def get_options
        # Specify unit options here based on the contents
        # getopts={}
        # getopts[:returnUnit] = params[:unit] if params[:unit]
        # getopts[:returnPerUnit] = params[:perUnit] if params[:perUnit]
        return {}
      end

      def find_profile
        # Return the AMEE::Profile::Profile to which the PI for this calculation
        # belongs, and update our stored UID to match.
        unless self.profile_uid
          prof ||= AMEE::Profile::ProfileList.new(connection).first
          prof ||= AMEE::Profile::Profile.create(connection)
          self.profile_uid=prof.uid
        end
      end

      def amee_name
        #Generate a unique name for the profile item.
        #Later, by interrogating metadata according to specifications of
        #Organisational model.
        UUIDTools::UUID.timestamp_create
      end

      def create_profile_item
        raise Exceptions::AlreadyHaveProfileItem unless profile_item_uid.blank?
        location = AMEE::Profile::Item.create(profile_category,
          amee_drill.data_item_uid,
          # Don't call data_item_uid,
          # cos we haven't got a profile to get the uid from, get it from the drill
          profile_options.merge(:get_item=>false,:name=>amee_name))
        self.profile_item_uid=location.split('/').last
      end

      MemoizedProfileInformation=[:profile_item,:data_item,:profile_category]
      #Have to wipe these every pass, because otherwise, they might change, e.g.
      # if metadata changes change the profile
      # it might be possible to gain more speed by being cleverer
      def new_memoize_pass
        MemoizedProfileInformation.each do |prop|
          instance_variable_set("@#{prop.to_s}",nil)
        end
      end

      def profile_item
        @profile_item||=AMEE::Profile::Item.get(connection, profile_item_path, get_options) unless profile_item_uid.blank?
      end

      def set_profile_item_values
        # Set the profile item values for the profile item.
        AMEE::Profile::Item.update(connection,profile_item_path, 
          profile_options.merge(:get_item=>false))
        #Clear the memoised profile item, to reload with updated values
        @profile_item=nil
      end

      def delete_profile_item
        AMEE::Profile::Item.delete(connection,profile_item_path)
        self.profile_item_uid=false
        @profile_item=nil
      end

      def profile_category_path
        "/profiles/#{profile_uid}#{path}"
      end

      def profile_item_path
        "#{profile_category_path}/#{profile_item_uid}"
      end

      def data_item_path
        "/data#{path}/#{data_item_uid}"
      end

      def data_item_uid
        profile_item.data_item_uid
      end

      def data_item
        @data_item||=AMEE::Data::Item.get(connection, data_item_path, get_options)
      end

      def profile_category
        @profile_category||=AMEE::Profile::Category.get(connection, profile_category_path)
      end

      def autodrill
        #Sometimes when a bunch of drills are specified,
        #this is enough to specify values for some more of them
        # list drills given in params, merged with values autopicked by amee driller
        picks=amee_drill.selections
        picks.each do |path,value|
          drill_by_path(path).value value
        end
      end

      public #pretend private
      #private -- missing friend feature, and
      #'friend' gem https://github.com/lsegal/friend
      #Isn't working.

      def amee_drill(options={})
        AMEE::Data::DrillDown.get(connection,"/data#{path}/drill?#{drill_options(options)}")
      end

    end
  end
end