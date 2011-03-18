module AMEE
  module DataAbstraction
    class OngoingCalculation < Calculation

      public

      #Need to make this friend to term, rather than public
      def chosen_terms(klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|!v.value.nil?}]
      end

      #Need to make this friend to term, rather than public
      #Suggest using 'friend' gem https://github.com/lsegal/friend
      def unset_terms(klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|v.value.nil?}]
      end

      def unset_inputs
        unset_terms AMEE::DataAbstraction::Input
      end

      def chosen_inputs
        chosen_terms AMEE::DataAbstraction::Input
      end

      def unset_outputs
        unset_terms AMEE::DataAbstraction::Output
      end

      def chosen_outputs
        chosen_terms AMEE::DataAbstraction::Output
      end

      def choose!(choice)
        
        choice.each do |k,v|
          self[k].value v unless v.blank?
        end
        
        drills.each_value do |d|       
          d.value nil unless d.valid_choice?
        end
       
        autodrill!    
      end

      def retreat!(label)
        found=false
        terms.each_value do |x|
          found||=(x.label==label)
          next unless found
          x.value nil
        end
      end

      def calculate!(profile=nil)
        return unless satisfied?
        profile ||= AMEE::Profile::ProfileList.new(connection).first
        profile ||= AMEE::Profile::Profile.create(connection)
        location = AMEE::Profile::Item.create(profile_category(profile),amee_drill.data_item_uid,
          profile_options.merge(:get_item=>false,:name=>UUIDTools::UUID.timestamp_create))
        item=AMEE::Profile::Item.get(connection, location, get_options)
        # Extract default result
        unset_outputs.values.each do |output|
          res=nil
          if output.path==:default
            res= item.amounts.find{|x| x[:default] == true}
          else
            res= item.amounts.find{|x| x[:type] == output.path}
          end
          output.value res[:value] if res
        end
        return self
      ensure
        # Tidy up
        if location
          AMEE::Profile::Item.delete(connection,location)
        end
      end

      def satisfied?
        unset_drills.values.empty? && unset_profiles.values.empty?
      end

      # Friend constructor for PrototypeCalculation ONLY
      def initialize
        super
      end

      private
      
      def unset_profiles
        unset_terms AMEE::DataAbstraction::Profile
      end

      def unset_drills
        unset_terms AMEE::DataAbstraction::Drill
      end

      def chosen_profiles
        chosen_terms AMEE::DataAbstraction::Profile
      end

      def chosen_drills
        chosen_terms AMEE::DataAbstraction::Drill
      end


      def drill_options
        chosen_drills.values.map{|x| "#{CGI.escape(x.path)}=#{CGI.escape(x.value)}"}.join("&")
      end
      def profile_options
        result={}
        chosen_profiles.values.each do |piv|
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
      def amee_drill
        AMEE::Data::DrillDown.get(connection,"/data#{path}/drill?#{drill_options}")
      end
      def profile_category(profile)
        AMEE::Profile::Category.get(connection, "/profiles/#{profile.uid}#{path}")
      end
      
      def connection
        AMEE::DataAbstraction.connection
      end

      def autodrill!
        #Sometimes when a bunch of drills are specified,
        #this is enough to specify values for some more of them
        # list drills given in params, merged with values autopicked by amee driller
        picks=amee_drill.selections
        picks.each do |path,value|
          drill_by_path(path).value value
        end
      end

      def next_drill
        unset_drills.values.first
      end

      def future_drills
        unset_drills.values[1..-1] || []
      end

    end
  end
end