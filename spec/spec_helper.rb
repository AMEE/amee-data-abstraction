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
    catuid=path.gsub(/\//,'-').to_sym
    struct.each do |selections,choices,answers|
      dataitemuid="#{catuid}:#{selections.map{|k,v|"#{k}-#{v}"}.join('-')}"
      pipath="/profiles/someprofileuid/#{path}/#{dataitemuid+"PI"}"
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
            and_return(pipath)
          flexmock(AMEE::Profile::Item).should_receive(:get).
            with(connection,pipath,{}).
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

def mock_existing_amee(mocks)
  #  mock_existing_amee(
  #      'transport/car/generic'=>{
  #        :myuid=>[ [['fuel','diesel'],['size','large']] , {'distance'=>5}, :somenumber ]
  #      }
  #    )
  flexmock(AMEE::Profile::ProfileList).should_receive(:new).
    with(connection).
    at_least.once.
    and_return(flexmock(:first=>flexmock(:uid=>:someprofileuid)))
  mocks.each do |path,struct1|
    struct1.each do |uid,struct|
      selections=struct.first
      pivs=struct[1]
      result=struct[2]
      failing=(struct.last==:failing) if struct.length>3
      catuid=path.gsub(/\//,'-').to_sym
      dataitemuid="#{catuid}:#{selections.map{|k,v|"#{k}-#{v}"}.join('-')}"
      pipath="/profiles/someprofileuid/#{path}/#{uid}"
      dipath="/data/#{path}/#{dataitemuid}"
      flexmock(AMEE::Profile::Item).should_receive(:update).
        with(connection,pipath,
        {:get_item=>false}.merge(pivs)).
        at_least.once unless failing
      mock_pi=flexmock(
        :amounts=>flexmock(:find=>{:value=>result}),
        :data_item_uid=>dataitemuid
      )
      pivs.each do |k,v|
        if failing
          mock_pi.should_receive(:value).with(k).and_return(v)
        else
          mock_pi.should_receive(:value).with(k).and_return(v).once
        end
      end
      flexmock(AMEE::Profile::Item).should_receive(:get).
        with(connection,pipath,{}).
        at_least.once.
        and_return(mock_pi)
      mock_di=flexmock
      selections.each do |k,v|
        if failing
          mock_di.should_receive(:value).with(k).and_return(v)
        else
          mock_di.should_receive(:value).with(k).and_return(v).once
        end
      end
      flexmock(AMEE::Data::Item).should_receive(:get).
        with(connection,dipath,{}).
        at_least.once.
        and_return(mock_di)

    end
  end
end