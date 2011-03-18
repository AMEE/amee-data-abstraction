require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
def drill_mocks
     flexmock(AMEE::Data::DrillDown).
      should_receive(:get).
      with(AMEE::DataAbstraction.connection,
      '/data/business/energy/electricity/grid/drill?').
      and_return(flexmock(:choices=>[],:selections=>{'country'=>'Argentina'}))
    flexmock(AMEE::Data::DrillDown).
      should_receive(:get).
      with(AMEE::DataAbstraction.connection,
      '/data/transport/car/generic/drill?').
      and_return(flexmock(:choices=>['diesel','petrol'],:selections=>{}))
    flexmock(AMEE::Data::DrillDown).
      should_receive(:get).
      with(AMEE::DataAbstraction.connection,
      '/data/transport/car/generic/drill?fuel=diesel').
      and_return(flexmock(:choices=>['large','small'],:selections=>{'fuel'=>'diesel'}))
    flexmock(AMEE::Data::DrillDown).
      should_receive(:get).
      with(AMEE::DataAbstraction.connection,
      '/data/transport/car/generic/drill?fuel=diesel&size=large').
      and_return(flexmock(:choices=>[],
        :selections=>{'fuel'=>'diesel','size'=>'large'},
        :data_item_uid=>:somediuid
      ))
end
describe AMEE::DataAbstraction::Calculation do
  before :all do
    @c=Electricity
    @t=Transport
  end
  it 'can have values chosen' do
    drill_mocks
    @c.inputs.values.map(&:label).should eql [:country,:energy_used]
    @c.inputs[:energy_used].path.should eql 'energyPerTime'
    @c.inputs[:energy_used].value.should eql nil
   
    @c[:energy_used].value.should eql nil
    d=@c.begin_calculation
    
    d.choose!(:energy_used=>5)
    d.chosen_inputs.values.map(&:value).should eql ['Argentina',5]
    d.unset_inputs.values.should be_empty
    d.inputs[:energy_used].path.should eql 'energyPerTime'
    d.inputs[:energy_used].value.should eql 5

    # Original should be unaffected by the choosing - clone generates a deep copy instance
    @c.inputs[:energy_used].path.should eql 'energyPerTime'
    @c.inputs[:energy_used].value.should eql nil
  end
  it 'knows when it is satisfied' do
    drill_mocks
    d=@c.begin_calculation
    d.satisfied?.should be_false
    d.choose!(:energy_used=>5)
    d.satisfied?.should be_true
  end
  it 'knows when its drills are satisfied' do
    drill_mocks
    @t.terms.values.map(&:label).should eql [:fuel,:size,:distance,:co2]
    t=@t.begin_calculation
    t.terms.values.map(&:label).should eql [:fuel,:size,:distance,:co2]
    t.satisfied?.should be_false
    t.choose!('fuel'=>'diesel')
    t.chosen_inputs.values.map(&:label).should eql [:fuel]
    t.unset_inputs.values.map(&:label).should eql [:size,:distance]
    t.satisfied?.should be_false
    t2=@t.begin_calculation
    t2.choose!('fuel'=>'diesel','size'=>'large')
    t2.chosen_inputs.values.map(&:label).should eql [:fuel,:size]
    t2.unset_inputs.values.map(&:label).should eql [:distance]
    t2.satisfied?.should be_false
    t3=@t.begin_calculation
    t3.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    t3.chosen_inputs.values.map(&:label).should eql [:fuel,:size,:distance]
    t3.unset_inputs.values.map(&:label).should eql []
    t3.satisfied?.should be_true
  end
  it 'can do a calculation' do
    drill_mocks
    flexmock(AMEE::Profile::ProfileList).should_receive(:new).
      with(AMEE::DataAbstraction.connection).
      and_return(flexmock(:first=>flexmock(:uid=>:somecatuid)))
    flexmock(AMEE::Profile::Category).should_receive(:get).
      with(AMEE::DataAbstraction.connection,"/profiles/somecatuid/transport/car/generic").
      and_return(:somecategory)
    flexmock(UUIDTools::UUID).should_receive(:timestamp_create).
      and_return(:sometimestamp)
    flexmock(AMEE::Profile::Item).should_receive(:create).
      with(:somecategory,:somediuid,
      {:get_item=>false,:name=>:sometimestamp,'distance'=>5}).
      and_return(:somelocation)
    flexmock(AMEE::Profile::Item).should_receive(:get).
      with(AMEE::DataAbstraction.connection,:somelocation,{}).
      and_return(flexmock(:amounts=>flexmock(:find=>{:value=>:somenumber})))
    flexmock(AMEE::Profile::Item).should_receive(:delete).
      with(AMEE::DataAbstraction.connection,:somelocation)
    mycalc=@t.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.outputs.values.first.value.should eql :somenumber
  end
end

