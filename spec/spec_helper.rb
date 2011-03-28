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

class AMEEMocker
  def initialize(test,options)
    @path=options[:path]
    sel=options[:selections]||[]
    @selections=ActiveSupport::OrderedHash[sel]
    @choices=options[:choices]||[]
    @result=options[:result]
    @params=options[:params]||{}
    @existing=options[:existing]||{}
    @test=test
    @mock_dc=test.flexmock(:path=>"/data/#{path}")
    @mock_id=test.flexmock
    @mock_ivds=[]
  end
  attr_accessor :path,:selections,:choices,:result,:params,:existing,:mock_dc,:mock_id,:mock_ivds
  attr_reader :test
  def catuid
    path.gsub(/\//,'-').to_sym
  end
  def select(opts)
    # Like an array of pairs, not a hash, for ordering reasons.
    opts.each do |k,v|
      @selections[k]=v
    end
  end
  def connection
    AMEE::DataAbstraction.connection
  end
  def dataitemuid
    "#{catuid}:#{selections.map{|k,v|"#{k}-#{v}"}.join('-')}"
  end
  def uid
    dataitemuid+"PI"
  end
  def pipath
    "/profiles/someprofileuid/#{path}/#{uid}"
  end
  def dipath
    "/data/#{path}/#{dataitemuid}"
  end
  def drill
    test.flexmock(AMEE::Data::DrillDown).
      should_receive(:get).
      with(connection,
      "/data/#{path}/drill?#{selections.map{|k,v|"#{k}=#{v}"}.join('&')}").
      at_least.once.
      and_return(test.flexmock(:choices=>choices,:selections=>Hash[selections],
        :data_item_uid=>dataitemuid))
    return self
  end
  def profile_list
    test.flexmock(AMEE::Profile::ProfileList).should_receive(:new).
      with(connection).at_least.once.
      and_return(test.flexmock(:first=>test.flexmock(:uid=>:someprofileuid)))
    return self
  end
  def timestamp
    test.flexmock(UUIDTools::UUID).should_receive(:timestamp_create).at_least.once.
      and_return(:sometimestamp)
    return self
  end
  def profile_category
    test.flexmock(AMEE::Profile::Category).should_receive(:get).
      with(connection,"/profiles/someprofileuid/#{path}").at_least.once.
      and_return(catuid)
    return self
  end
  def itemdef_drills(some_drills)
    mock_id.should_receive(:drill_downs).and_return(some_drills)
  end
  def item_value_definition(path,compulsories=[],optionals=[],forbiddens=[])
    ivd=test.flexmock :path=>path
    compulsories.each do |compulsory|
      ivd.should_receive(:compulsory?).with(compulsory).and_return(true)
      ivd.should_receive(:optional?).with(compulsory).and_return(false)
    end
    optionals.each do |optional|
      ivd.should_receive(:optional?).with(optional).and_return(true)
      ivd.should_receive(:compulsory?).with(optional).and_return(false)
    end
    forbiddens.each do |forbidden|
      ivd.should_receive(:optional?).with(forbidden).and_return(false)
      ivd.should_receive(:compulsory?).with(forbidden).and_return(false)
    end
    mock_ivds.push ivd
    return self
  end
  def item_value_definitions
    mock_id.should_receive(:item_value_definition_list).at_least.once.and_return(mock_ivds)
    return self
  end
  def item_definition(name=:itemdef_name)
    mock_id.should_receive(:name).and_return(name)
    mock_dc.should_receive(:item_definition).at_least.once.and_return(mock_id)
    return self
  end
  def data_category
    test.flexmock(AMEE::Data::Category).should_receive(:get).
      with(connection,"/data/#{path}").at_least.once.
      and_return(mock_dc)
    return self
  end
  def create
    test.flexmock(AMEE::Profile::Item).should_receive(:create).
      with(catuid,dataitemuid,
      {:get_item=>false,:name=>:sometimestamp}.merge(params)).
      at_least.once.
      and_return(pipath)
    return self
  end
  def get(with_pi=false,failing=false)
    mock_pi=test.flexmock(
      :amounts=>test.flexmock(:find=>{:value=>result}),
      :data_item_uid=>dataitemuid
    )
    mock_di=test.flexmock
    if with_pi
      from_amee=existing.clone
      params.each {|key,val| from_amee.delete key}
      from_amee.each do |k,v|
        if failing
          mock_pi.should_receive(:value).with(k).and_return(v)
        else
          mock_pi.should_receive(:value).with(k).and_return(v).once
        end
      end
      selections.each do |k,v|
        if failing
          mock_di.should_receive(:value).with(k).and_return(v)
        else
          mock_di.should_receive(:value).with(k).and_return(v).once
        end
      end
      test.flexmock(AMEE::Data::Item).should_receive(:get).
        with(connection,dipath,{}).
        at_least.once.
        and_return(mock_di)
    end
    test.flexmock(AMEE::Profile::Item).should_receive(:get).
      with(connection,pipath,{}).
      at_least.once.
      and_return(mock_pi)
    return self
  end
  def delete
    test.flexmock(AMEE::Profile::Item).should_receive(:delete).
      at_least.once.
      with(connection,pipath)
    return self
  end
  def update
    test.flexmock(AMEE::Profile::Item).should_receive(:update).
      with(connection,pipath,
      {:get_item=>false}.merge(existing).merge(params)).
      at_least.once
    return self
  end
end