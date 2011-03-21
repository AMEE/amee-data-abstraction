module AMEE
  module DataAbstraction
    class OngoingCalculation < Calculation

      public



      def unset_inputs
        unset_terms Input
      end

      def chosen_inputs
        chosen_terms Input
      end

      def unset_outputs
        unset_terms Output
      end

      def chosen_outputs
        chosen_terms Output
      end

      def visible_inputs
        visible_terms Input
      end
	 		 	
      def visible_outputs	 	
        visible_terms Output
      end


      def choose!(choice)
        
        choice.each do |k,v|
          self[k].value v unless v.blank?
        end

        #Clear out any invalid choices
        inputs.each_value do |d|
          d.validate! # Up to each kind of quantity to decide whether to unset itself
          # or raise an exception, if it is invalid.
          # Typical behaviour is to simply set one's value to zero.
        end
       
        autodrill!    
      end

      def calculate!(profile=nil)
        return unless satisfied?
        profile ||= AMEE::Profile::ProfileList.new(connection).first
        profile ||= AMEE::Profile::Profile.create(connection)
        location = AMEE::Profile::Item.create(profile_category(profile),amee_drill.data_item_uid,
          profile_options.merge(:get_item=>false,:name=>UUIDTools::UUID.timestamp_create))
        item=AMEE::Profile::Item.get(connection, location, get_options)
        # Extract default result
        unset_terms(Output).values.each do |output|
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
        unset_terms(Input).values.empty?
      end

      # Friend constructor for PrototypeCalculation ONLY
      def initialize
        super
      end

      private

      def drill_options
        fu=unset_terms(Drill).values.first
        raise Exceptions::OrderEntryException unless \
          after(fu.label,Drill).values.all?{|x|x.unset?} if fu
        chosen_terms(Drill).values.map{|x| "#{CGI.escape(x.path)}=#{CGI.escape(x.value)}"}.join("&")
      end

      def profile_options
        result={}
        chosen_terms(Profile).values.each do |piv|
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

      public #pretend private
      #private -- missing friend feature, and
      #'friend' gem https://github.com/lsegal/friend
      #Isn't working.

      def amee_drill
        AMEE::Data::DrillDown.get(connection,"/data#{path}/drill?#{drill_options}")
      end

      #Friend for drill term, move to private.
      def retreat!(label)
        inputs.values.select{|x| x.after? label}.each{|x| x.value nil}
        inputs[label].value nil
      end

      #Need to make this friend to term, rather than public
      def chosen_terms(klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|v.set?}]
      end

      def visible_terms(klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|v.visible?}]
      end

      #Need to make this friend to term, rather than public
      def unset_terms(klass=nil)
        ActiveSupport::OrderedHash[terms(klass).stable_select{|k,v|!v.set?}]
      end

    end
  end
end