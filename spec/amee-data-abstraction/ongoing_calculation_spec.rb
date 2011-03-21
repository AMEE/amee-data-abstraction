require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
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
describe OngoingCalculation do
  it 'can return set and unset inputs' do
    d=Electricity.begin_calculation
    d.chosen_inputs.keys.should eql [:country]
    d.unset_inputs.keys.should eql [:energy_used]
    d[:energy_used].value :somevalue
    d.chosen_inputs.keys.should eql [:country,:energy_used]
    d.unset_inputs.keys.should eql []
  end
  it 'can return set and unset terms' do
    d=Electricity.begin_calculation
    d.chosen_terms.keys.should eql [:country]
    d.unset_terms.keys.should eql [:energy_used,:co2]
    d[:energy_used].value :somevalue
    d.chosen_terms.keys.should eql [:country,:energy_used]
    d.unset_terms.keys.should eql [:co2]
  end
  it 'can return set and unset outputs' do
    d=Electricity.begin_calculation
    d.chosen_outputs.keys.should eql []
    d.unset_outputs.keys.should eql [:co2]
    d[:co2].value 5
    d.chosen_outputs.keys.should eql [:co2]
    d.unset_outputs.keys.should eql []
  end
  it 'can have values chosen' do
    drill_mocks
    
    d=Electricity.begin_calculation

    d.chosen_inputs.values.map(&:value).should eql ['argentina']
    d.unset_inputs.values.map(&:value).should eql [nil]

    d.choose!(:energy_used=>5.0)

    d.chosen_inputs.values.map(&:value).should eql ['argentina',5.0]
    d.unset_inputs.values.should be_empty
  end
  it 'knows when it is satisfied' do
    drill_mocks
    d=Electricity.begin_calculation
    d.satisfied?.should be_false
    d.choose!(:energy_used=>5.0)
    d.satisfied?.should be_true
  end
  it 'knows which drills are set, and whether it is satisfied' do
    drill_mocks
    t=Transport.begin_calculation
    t.terms.keys.should eql [:fuel,:size,:distance,:co2]
    t.satisfied?.should be_false

    t.choose!('fuel'=>'diesel')
    t.chosen_inputs.values.map(&:label).should eql [:fuel]
    t.unset_inputs.values.map(&:label).should eql [:size,:distance]
    t.satisfied?.should be_false

    t2=Transport.begin_calculation
    t2.choose!('fuel'=>'diesel','size'=>'large')
    t2.chosen_inputs.values.map(&:label).should eql [:fuel,:size]
    t2.unset_inputs.values.map(&:label).should eql [:distance]
    t2.satisfied?.should be_false

    t3=Transport.begin_calculation
    t3.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    t3.chosen_inputs.values.map(&:label).should eql [:fuel,:size,:distance]
    t3.unset_inputs.values.map(&:label).should eql []
    t3.satisfied?.should be_true
  end
  it 'can do a calculation' do
    drill_mocks
    flexmock(AMEE::Profile::ProfileList).should_receive(:new).
      with(connection).
      and_return(flexmock(:first=>flexmock(:uid=>:somecatuid)))
    flexmock(AMEE::Profile::Category).should_receive(:get).
      with(connection,"/profiles/somecatuid/transport/car/generic").
      and_return(:somecategory)
    flexmock(UUIDTools::UUID).should_receive(:timestamp_create).
      and_return(:sometimestamp)
    flexmock(AMEE::Profile::Item).should_receive(:create).
      with(:somecategory,:somediuid,
      {:get_item=>false,:name=>:sometimestamp,'distance'=>5}).
      and_return(:somelocation)
    flexmock(AMEE::Profile::Item).should_receive(:get).
      with(connection,:somelocation,{}).
      and_return(flexmock(:amounts=>flexmock(:find=>{:value=>:somenumber})))
    flexmock(AMEE::Profile::Item).should_receive(:delete).
      with(connection,:somelocation)
    mycalc=Transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.outputs.values.first.value.should eql :somenumber
  end
end

