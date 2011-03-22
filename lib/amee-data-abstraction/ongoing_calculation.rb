module AMEE
  module DataAbstraction
    class OngoingCalculation < Calculation

      public

      def choose!(choice)
        
        choice.each do |k,v|
          self[k].value v unless v.blank?
        end

        #Clear out any invalid choices
        inputs.each do |d|
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
        outputs.unset.each do |output|
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
        inputs.unset.empty?
      end

      # Friend constructor for PrototypeCalculation ONLY
      def initialize
        super
      end

      private

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

      def amee_drill(options={})
        AMEE::Data::DrillDown.get(connection,"/data#{path}/drill?#{drill_options(options)}")
      end

    end
  end
end