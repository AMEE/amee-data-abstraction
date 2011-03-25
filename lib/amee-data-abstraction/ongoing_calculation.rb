module AMEE
  module DataAbstraction
    class OngoingCalculation < Calculation

      public

      def choose!(choice)
        self.profile_uid= choice.delete(:profile_uid)
        self.profile_item_uid= choice.delete(:profile_item_uid)

        choice.each do |k,v|
          raise Exceptions::NoSuchTerm.new(k) unless self[k]
          self[k].value v unless v.blank?
        end

        #Clear out any invalid choices
        inputs.each do |d|
          d.validate! # Up to each kind of quantity to decide whether to unset itself
          # or raise an exception, if it is invalid.
          # Typical behaviour is to simply set one's value to zero.
        end
       
        autodrill
      end

      def calculate!
        syncronize_with_amee
      end

      # Friend constructor for PrototypeCalculation ONLY
      def initialize
        super
      end

      def satisfied?
        inputs.unset.empty?
      end


      private

      def load_outputs
        outputs.each do |output|
          res=nil
          if output.path==:default
            res= profile_item.amounts.find{|x| x[:default] == true}
          else
            res= profile_item.amounts.find{|x| x[:type] == output.path}
          end
          output.value res[:value] if res
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
        profiles.each do |term|
          ameeval=profile_item.value(term.path)
          raise Exceptions::Syncronization if term.set? && ameeval!=term.value
          term.value ameeval
        end
      end

      def load_drills
        return unless profile_item
        drills.each do |term|
          ameeval=data_item.value(term.path)
          raise Exceptions::Syncronization if term.set? && ameeval!=term.value
          term.value ameeval
        end
      end

      def syncronize_with_amee
        find_profile
        load_profile_item_values
        load_drills
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

      attr_accessor :profile_uid,:profile_item_uid
      
      def drill_options(options={})
        to=options.delete(:before)
        drills_to_use=to ? drills.before(to).set : drills.set
        drills_to_use.map{|x| "#{CGI.escape(x.path)}=#{CGI.escape(x.value)}"}.join("&")
      end

      def profile_options
        result={}
        profiles.set.each do |piv|
          result[piv.path]=piv.value
        end
        return result
      end
      def get_options
        # Specify unit options here based on the contents
        #getopts={}
        #getopts[:returnUnit] = params[:unit] if params[:unit]
        #getopts[:returnPerUnit] = params[:perUnit] if params[:perUnit]
        return {}
      end

      def find_profile
        # Return the AMEE::Profile::Profile to which the PI for this calculation
        # belongs, and update our stored UID to match.
        prof = AMEE::Profile::Profile.load(profile_uid) if profile_uid
        prof ||= AMEE::Profile::ProfileList.new(connection).first
        prof ||= AMEE::Profile::Profile.create(connection)
        self.profile_uid=prof.uid
        return prof
      end

      def amee_name
        #Generate a unique name for the profile item.
        #Later, by interrogating metadata according to specifications of
        #Organisational model.
        UUIDTools::UUID.timestamp_create
      end

      def create_profile_item
        raise Exceptions::AlreadyHaveProfileItem if profile_item_uid
        location = AMEE::Profile::Item.create(profile_category,
          amee_drill.data_item_uid,
          # Don't call data_item_uid,
          # cos we haven't got a profile to get the uid from, get it from the drill
          profile_options.merge(:get_item=>false,:name=>amee_name))
        self.profile_item_uid=location.split('/').last
      end

      def profile_item
        AMEE::Profile::Item.get(connection, profile_item_path, get_options) if profile_item_uid
      end

      def set_profile_item_values
        # Set the profile item values for the profile item.
        AMEE::Profile::Item.update(connection,profile_item_path, 
          profile_options.merge(:get_item=>false))
      end

      def delete_profile_item
        AMEE::Profile::Item.delete(connection,profile_item_path)
        self.profile_item_uid=false
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
        AMEE::Data::Item.get(connection, data_item_path, get_options)
      end

      def profile_category
        AMEE::Profile::Category.get(connection, profile_category_path)
      end
      
      def connection
        AMEE::DataAbstraction.connection
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