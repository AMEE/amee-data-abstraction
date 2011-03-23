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

def drill_mocks
  mocks={
    'business/energy/electricity/grid'=> [
      [[],['argentina','mexico']],
      [[['country','argentina']],[]]
    ],
    'transport/car/generic'=> [
      [{},['diesel','petrol']],
      [[['fuel','diesel']],['large','small']],
      [[['fuel','diesel'],['size','large']],[],:somediuid]
    ]}
  mocks.each do |path,struct|
    struct.each do |selections,choices,uid|
 
      flexmock(AMEE::Data::DrillDown).
    should_receive(:get).
    with(connection,
    "/data/#{path}/drill?#{selections.map{|k,v|"#{k}=#{v}"}.join('&')}").
    and_return(flexmock(:choices=>choices,:selections=>Hash[selections],:data_item_uid=>uid))
    end
  end
end