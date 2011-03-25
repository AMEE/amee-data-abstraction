require 'rubygems'
require 'spec'
require 'rspec_spinner'
require 'flexmock'
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'amee'
require 'amee-internal'
require 'amee-data-abstraction'

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

AMEE::DataAbstraction.connection=FlexMock.new('connection') #Global connection mock, shouldn't receive anything, as we mock the individual amee-ruby calls in the tests

Dir.glob(File.dirname(__FILE__) + '/fixtures/*') do |filename|
  require filename
end

include AMEE::DataAbstraction

def mock_amee(mocks)
  mocks.each do |path,struct|
    catuid=path.gsub(/\//,',').to_sym
    struct.each do |selections,choices,answers|
      dataitemuid="#{catuid},#{selections.map{|k,v|"#{k}=#{v}"}.join(',')}"
      piuid=dataitemuid+"PI"
      flexmock(AMEE::Data::DrillDown).
        should_receive(:get).
        with(connection,
        "/data/#{path}/drill?#{selections.map{|k,v|"#{k}=#{v}"}.join('&')}").
        at_least.once.
        and_return(flexmock(:choices=>choices,:selections=>Hash[selections],
          :data_item_uid=>dataitemuid))
      unless answers.blank? # We are to create a PID.
        flexmock(AMEE::Profile::ProfileList).should_receive(:new).
          with(connection).
          at_least.once.
          and_return(flexmock(:first=>flexmock(:uid=>:someprofileuid)))
        flexmock(AMEE::Profile::Category).should_receive(:get).
          with(connection,"/profiles/someprofileuid/#{path}").at_least.once.
          and_return(catuid)
        flexmock(UUIDTools::UUID).should_receive(:timestamp_create).at_least.once.
          and_return(:sometimestamp)
        answers.each do |params,result|
          flexmock(AMEE::Profile::Item).should_receive(:create).
            with(catuid,dataitemuid,
            {:get_item=>false,:name=>:sometimestamp}.merge(params)).
            at_least.once.
            and_return(piuid)         
          flexmock(AMEE::Profile::Item).should_receive(:get).
            with(connection,piuid,{}).
            at_least.once.
            and_return(flexmock(:amounts=>flexmock(:find=>{:value=>result})))
          # Removing delete, PIs persisted for now.
#          flexmock(AMEE::Profile::Item).should_receive(:delete).
#            at_least.once.
#            with(connection,piuid)
        end
      end
    end
  end
  
  
  
end