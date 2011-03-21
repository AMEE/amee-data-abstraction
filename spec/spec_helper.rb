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
  flexmock(AMEE::Data::DrillDown).
    should_receive(:get).
    with(connection,
    '/data/business/energy/electricity/grid/drill?').
    and_return(flexmock(:choices=>['argentina','mexico'],:selections=>{}))
  flexmock(AMEE::Data::DrillDown).
    should_receive(:get).
    with(connection,
    '/data/business/energy/electricity/grid/drill?country=argentina').
    and_return(flexmock(:choices=>[],:selections=>{'country'=>'argentina'}))
  flexmock(AMEE::Data::DrillDown).
    should_receive(:get).
    with(connection,
    '/data/transport/car/generic/drill?').
    and_return(flexmock(:choices=>['diesel','petrol'],:selections=>{}))
  flexmock(AMEE::Data::DrillDown).
    should_receive(:get).
    with(connection,
    '/data/transport/car/generic/drill?fuel=diesel').
    and_return(flexmock(:choices=>['large','small'],:selections=>{'fuel'=>'diesel'}))
  flexmock(AMEE::Data::DrillDown).
    should_receive(:get).
    with(connection,
    '/data/transport/car/generic/drill?fuel=diesel&size=large').
    and_return(flexmock(:choices=>[],
      :selections=>{'fuel'=>'diesel','size'=>'large'},
      :data_item_uid=>:somediuid
    ))
end