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
    AMEEMocker.new(self,:path=>'business/energy/electricity/grid',
      :selections=>[['country','argentina']],
      :choices=>[]).drill

    d=Electricity.begin_calculation

    d.inputs.set.values.should eql ['argentina']
    d.inputs.unset.values.should eql [nil]

    d.choose!(:energy_used=>5.0)

    d.inputs.set.values.should eql ['argentina',5.0]
    d.inputs.unset.values.should be_empty
  end
  it 'knows when it is satisfied' do
    AMEEMocker.new(self,:path=>'business/energy/electricity/grid',
      :selections=>[['country','argentina']],
      :choices=>[]).drill
    d=Electricity.begin_calculation
    d.satisfied?.should be_false
    d.choose!(:energy_used=>5.0)
    d.satisfied?.should be_true
  end
  it 'knows which drills are set, and whether it is satisfied' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
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
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.profile_category.timestamp.create.get
    mycalc=Transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end
  it 'can respond appropriately to inconsistent drills' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mycalc=Transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'banana','distance'=>5)
    mycalc.drills.values.should eql ['diesel',nil]
  end
  it 'does not send general metadata to AMEE' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.profile_category.timestamp.create.get
    mycalc=ElectricityAndTransport[:transport].begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5,'department'=>'stuff')
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end
  it 'raises exception if choice supplied for invalid term' do
    mycalc=Transport.begin_calculation
    lambda{mycalc.choose!('fuel'=>'diesel','banana'=>'large','distance'=>5)}.
      should raise_exception Exceptions::NoSuchTerm
  end
  it 'can be supplied just a UID, and recover PIVs and drill values from AMEE' do
    mycalc=Transport.begin_calculation
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :result=>:somenumber,
      :existing=>{'distance'=>5},:choices=>['petrol','diesel'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.profile_list.update.get(true)
    mycalc.choose!(:profile_item_uid=>mocker.uid)
    mycalc.calculate!
    mycalc[:fuel].value.should eql 'diesel'
    mycalc[:distance].value.should eql 5
    mycalc.outputs.first.value.should eql :somenumber
  end
  it 'refuses to load values from AMEE which conflict with local drill values' do
    mycalc=Transport.begin_calculation
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :result=>:somenumber,
      :existing=>{'distance'=>7},
      :params=>{'distance'=>7},:choices=>['petrol','diesel'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.profile_list.get(true,true).delete
    existing_uid=mocker.uid
    mocker.select('size'=>'small')
    mocker.drill.profile_category.timestamp.create.get
    mycalc.choose!(:profile_item_uid=>existing_uid,'fuel'=>'diesel','size'=>'small','distance'=>7)
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end
  it 'lets local profile values replace and update those in amee' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :result=>:somenumber,
      :choices=>['petrol','diesel'],
      :params=>{'distance'=>9},
      :existing=>{'distance'=>5}
    )
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.update.get(true)
    mycalc=Transport.begin_calculation
    mycalc.choose!(:profile_item_uid=>mocker.uid,'fuel'=>'diesel','size'=>'large','distance'=>9)
    mycalc.calculate!
    mycalc[:distance].value.should eql 9
  end
  it 'can be calculated, then recalculated, loading from AMEE the second time' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.profile_category.timestamp.create

    mocker.existing={'distance'=>5}
    mocker.params={'distance'=>9}
    mocker.update.get(true)

    mycalc=Transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>9)
    mycalc.calculate!
    mycalc[:distance].value.should eql 9
  end
  it 'can be calculated, then change drill, recreating the second time' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.profile_category.timestamp.create.get(true,true).delete

    mocker.select('size'=>'small')
    mocker.drill.create.get

    mycalc=Transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.choose!('fuel'=>'diesel','size'=>'small')
    mycalc.calculate!
    mycalc[:distance].value.should eql 5
  end
  it 'memoizes profile information, but not across a pass' do
    mycalc=Transport.begin_calculation
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :result=>:somenumber,
      :existing=>{'distance'=>5},:choices=>['petrol','diesel'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.profile_list.update.get(true,false,true)
    mycalc.choose!(:profile_item_uid=>mocker.uid)
    mycalc.calculate!
    mycalc.send(:profile_item)
    mycalc[:fuel].value.should eql 'diesel'
    mycalc[:distance].value.should eql 5
    mycalc.outputs.first.value.should eql :somenumber
  end
  it 'creates profile item with start end dates if appropriate metadata provided' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5,
        :start_date=>Date.parse("1976-10-19"),
        :end_date=>Date.parse("2011-1-1")})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.profile_category.timestamp.create.get
    myproto=Transport.clone
    myproto.instance_eval{
      start_and_end_dates
    }
    mycalc=myproto.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5,'start_date'=>"1976-10-19",'end_date'=>"2011-1-1")
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end
  it 'does not pass start end dates if inappropriate value provided' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5,
        :end_date=>Date.parse("2011-1-1")})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.drill
    mocker.profile_list.profile_category.timestamp.create.get
    myproto=Transport.clone
    myproto.instance_eval{
      start_and_end_dates
    }
    mycalc=myproto.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5,'start_date'=>"banana",'end_date'=>"2011-1-1")
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end
end

