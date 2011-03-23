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

def mocks
  mocks={
    'business/energy/electricity/grid'=> [
      [[],['argentina','mexico']],
      [[['country','argentina']],[]]
    ],
    'transport/car/generic'=> [
      [{},['diesel','petrol']],
      [[['fuel','diesel']],['large','small']],
      [[['fuel','diesel'],['size','large']],[]]
    ]}
  mocks.each do |path,struct|
    catuid=path.gsub(/\//,',').to_sym
    flexmock(AMEE::Profile::Category).should_receive(:get).
      with(connection,"/profiles/someprofileuid/#{path}").
      and_return(catuid)
    struct.each do |selections,choices|
      dataitemuid="#{catuid},#{selections.map{|k,v|"#{k}=#{v}"}.join(',')}"
      piuid=dataitemuid+"PI"
      flexmock(AMEE::Data::DrillDown).
        should_receive(:get).
        with(connection,
        "/data/#{path}/drill?#{selections.map{|k,v|"#{k}=#{v}"}.join('&')}").
        and_return(flexmock(:choices=>choices,:selections=>Hash[selections],
          :data_item_uid=>dataitemuid))
      flexmock(AMEE::Profile::Item).should_receive(:create).
        with(catuid,dataitemuid,
        {:get_item=>false,:name=>:sometimestamp,'distance'=>5}).
        and_return(piuid)
      flexmock(AMEE::Profile::Item).should_receive(:get).
        with(connection,piuid,{}).
        and_return(flexmock(:amounts=>flexmock(:find=>{:value=>:somenumber})))
      flexmock(AMEE::Profile::Item).should_receive(:delete).
        with(connection,piuid)
    end
  end
  flexmock(AMEE::Profile::ProfileList).should_receive(:new).
    with(connection).
    and_return(flexmock(:first=>flexmock(:uid=>:someprofileuid)))
  flexmock(UUIDTools::UUID).should_receive(:timestamp_create).
    and_return(:sometimestamp)
  
end