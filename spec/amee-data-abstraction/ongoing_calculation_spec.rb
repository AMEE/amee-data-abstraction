require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe OngoingCalculation do
  it 'can return set and unset inputs' do
    d=Electricity.begin_calculation
    d.inputs.set.labels.should eql [:country]
    d.inputs.unset.labels.should eql [:energy_used]
    d[:energy_used].value :somevalue
    d.inputs.set.labels.should eql [:country,:energy_used]
    d.inputs.unset.labels.should eql []
  end
  it 'can return set and unset terms' do
    d=Electricity.begin_calculation
    d.set.labels.should eql [:country]
    d.unset.labels.should eql [:energy_used,:co2]
    d[:energy_used].value :somevalue
    d.set.labels.should eql [:country,:energy_used]
    d.unset.labels.should eql [:co2]
  end
  it 'can return set and unset outputs' do
    d=Electricity.begin_calculation
    d.outputs.set.labels.should eql []
    d.outputs.unset.labels.should eql [:co2]
    d[:co2].value 5
    d.outputs.set.labels.should eql [:co2]
    d.outputs.unset.labels.should eql []
  end
  it 'can have values chosen' do
    drill_mocks
    
    d=Electricity.begin_calculation

    d.inputs.set.values.should eql ['argentina']
    d.inputs.unset.values.should eql [nil]

    d.choose!(:energy_used=>5.0)

    d.inputs.set.values.should eql ['argentina',5.0]
    d.inputs.unset.values.should be_empty
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
    t.terms.labels.should eql [:fuel,:size,:distance,:co2]
    t.satisfied?.should be_false

    t.choose!('fuel'=>'diesel')
    t.inputs.set.labels.should eql [:fuel]
    t.inputs.unset.labels.should eql [:size,:distance]
    t.satisfied?.should be_false

    t2=Transport.begin_calculation
    t2.choose!('fuel'=>'diesel','size'=>'large')
    t2.inputs.set.labels.should eql [:fuel,:size]
    t2.inputs.unset.labels.should eql [:distance]
    t2.satisfied?.should be_false

    t3=Transport.begin_calculation
    t3.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    t3.inputs.set.labels.should eql [:fuel,:size,:distance]
    t3.inputs.unset.labels.should eql []
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
    mycalc.outputs.first.value.should eql :somenumber
  end
end

