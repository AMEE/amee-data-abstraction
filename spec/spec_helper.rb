require 'rubygems'
require 'rspec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'amee-data-abstraction'

# Fake up Rails.root to be fixtures directory
class Rails
  def self.root
    File.dirname(__FILE__) + '/fixtures'
  end
  def self.logger
    nil
  end
end

RSpec.configure do |config|
  config.mock_with :flexmock
  config.after(:each) do
    delete_lock_files
  end
end

def delete_lock_files
  config_dir = Dir.new("#{Rails.root}/config/calculations")
  config_dir.each do |file|
    File.delete("#{config_dir.path}/#{file}") if file =~ /lock/
  end
end

AMEE::DataAbstraction.connection=FlexMock.new('connection') #Global connection mock, shouldn't receive anything, as we mock the individual amee-ruby calls in the tests

# Fake up Rails.root to be fixtures directory
class Rails
  def self.root
    File.dirname(__FILE__) + '/fixtures'
  end
  def self.logger
    nil
  end
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
    @mock_rvds=[]
  end

  attr_accessor :path,:selections,:choices,:result,:params,
    :existing,:mock_dc,:mock_id,:mock_ivds,:mock_rvds

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

  # This represents the skipping of drill choices which occur on an AMEE drill
  # down when only one choice exists for a given drill - it skips to the next,
  # offering the next set of choices or a uid. In these cases, the skipped drill
  # is set as an automatic selection
  def drill_with_skip(skipped_selections=[])
    test.flexmock(AMEE::Data::DrillDown).
      should_receive(:get).
      with(connection,
      "/data/#{path}/drill?#{selections.map{|k,v|"#{k}=#{v}"}.join('&')}").
      at_least.once.
      and_return(test.flexmock(:choices=>choices,:selections=>Hash[selections].merge(skipped_selections),
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
    return self
  end
  
  def return_value_definition(path,unit=nil,per_unit=nil)
    rvd=test.flexmock :name=>path
    rvd.should_receive(:unit).and_return unit
    rvd.should_receive(:perunit).and_return per_unit
    mock_rvds.push rvd
    return self
  end

  def return_value_definitions
    test.flexmock(AMEE::Admin::ReturnValueDefinitionList).should_receive(:new).
        with(connection,:itemdefuid).and_return mock_rvds
      return self
  end

  def item_value_definition_metadata(meta)
    AMEE::Admin::ItemValueDefinition.new(:meta=>meta).meta
  end

  def item_value_definition(path,compulsories=[],optionals=[],forbiddens=[],choices=[],unit=nil,per_unit=nil,profile=true,drill=false,default=nil,type=nil,wikidoc=nil)
    ivd=test.flexmock :path=>path
    ivd.should_receive(:name).and_return path.to_s.humanize
    ivd.should_receive(:profile?).and_return profile
    ivd.should_receive(:drill?).and_return drill
    ivd.should_receive(:versions).and_return ['2.0']
    ivd.should_receive(:unit).and_return unit
    ivd.should_receive(:perunit).and_return per_unit
    ivd.should_receive(:choices).and_return choices
    ivd.should_receive(:default).and_return default
    ivd.should_receive(:valuetype).and_return type
    ivd.should_receive(:meta).and_return(item_value_definition_metadata(:wikidoc=>wikidoc))#.should_receive(:wikidoc).and_return wikidoc
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

  def usages(someusages)
    mock_id.should_receive(:usages).and_return(someusages)
    return self
  end

  def item_definition(name=:itemdef_name)
    mock_id.should_receive(:name).and_return(name)
    mock_id.should_receive(:uid).and_return(:itemdefuid)
    mock_dc.should_receive(:item_definition).at_least.once.and_return(mock_id)
    return self
  end

  def data_category
    test.flexmock(AMEE::Data::Category).should_receive(:get).
      with(connection,"/data/#{path}").at_least.once.
      and_return(mock_dc)
    return self
  end

  def create_and_get
    mock_pi=test.flexmock(
      :amounts=>test.flexmock(:find=>{:value=>result}),
      :data_item_uid=>dataitemuid,
      :uid=>uid
    )
    test.flexmock(AMEE::Profile::Item).should_receive(:create).
      with(catuid,dataitemuid,
      {:get_item=>true,:name=>:sometimestamp}.merge(params)).
      at_least.once.
      and_return(mock_pi)
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

  def get(with_pi=false,failing=false,once=false)
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
          mock_pi.should_receive(:values).and_return([{:path => k,:value => v }])
        else
          mock_pi.should_receive(:values).and_return([{:path => k,:value => v }]).once
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
    if once
      test.flexmock(AMEE::Profile::Item).should_receive(:get).
      with(connection,pipath,{}).
      at_least.once.
      and_return(mock_pi)
    else
    test.flexmock(AMEE::Profile::Item).should_receive(:get).
      with(connection,pipath,{}).
      at_least.once.
      and_return(mock_pi)
    end
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
      {:get_item=>true}.merge(existing).merge(params)).
      at_least.once
    return self
  end
end