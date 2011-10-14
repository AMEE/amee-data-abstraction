require 'spec_helper'

describe OngoingCalculation do
  before :all do
    @elec = CalculationSet.find(:electricity)[:electricity]
    @transport = CalculationSet.find(:transport)[:transport]
    @elec_and_transport = CalculationSet.find(:electricity_and_transport)
  end
  
  it 'can return set and unset inputs' do
    d=@elec.begin_calculation
    d.inputs.set.labels.should eql [:country]
    d.inputs.unset.labels.should eql [:energy_used]
    d[:energy_used].value :somevalue
    d.inputs.set.labels.should eql [:country,:energy_used]
    d.inputs.unset.labels.should eql []
  end
  it 'can return set and unset terms' do
    d=@elec.begin_calculation
    d.set.labels.should eql [:country]
    d.unset.labels.should eql [:energy_used,:co2]
    d[:energy_used].value :somevalue
    d.set.labels.should eql [:country,:energy_used]
    d.unset.labels.should eql [:co2]
  end
  it 'can return set and unset outputs' do
    d=@elec.begin_calculation
    d.outputs.set.labels.should eql []
    d.outputs.unset.labels.should eql [:co2]
    d[:co2].value 5
    d.outputs.set.labels.should eql [:co2]
    d.outputs.unset.labels.should eql []
  end
  it 'can clear outputs' do
    d=@elec.begin_calculation
    d.outputs.unset.labels.should eql [:co2]
    d[:co2].value 5
    d[:co2].value.should eql 5
    d.clear_outputs
    d[:co2].value.should be_nil
  end
  it 'can have values chosen' do
    AMEEMocker.new(self,:path=>'business/energy/electricity/grid',
      :selections=>[['country','argentina']],
      :choices=>[]).drill

    d=@elec.begin_calculation

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
    d=@elec.begin_calculation
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
    t=@transport.begin_calculation
    t.terms.labels.should eql [:fuel,:size,:distance,:co2]
    t.satisfied?.should be_false

    t.choose!('fuel'=>'diesel')
    t.inputs.set.labels.should eql [:fuel]
    t.inputs.unset.labels.should eql [:size,:distance]
    t.satisfied?.should be_false

    t2=@transport.begin_calculation
    t2.choose!('fuel'=>'diesel','size'=>'large')
    t2.inputs.set.labels.should eql [:fuel,:size]
    t2.inputs.unset.labels.should eql [:distance]
    t2.satisfied?.should be_false

    t3=@transport.begin_calculation
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
    mocker.profile_list.profile_category.timestamp.create_and_get
    mycalc=@transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
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
    mocker.profile_list.profile_category.timestamp.create_and_get
    mycalc=@elec_and_transport[:transport].begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5,'department'=>'stuff')
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end

  #This exception has been removed, to support the case where the persistence module
  #had a saved calculation from before a configuration file changed. We might want to
  #do something more sophisticated.
  #it 'raises exception if choice supplied for invalid term' do
  #  mycalc=Transport.begin_calculation
  #  mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
  #    :choices=>['diesel','petrol'],
  #    :result=>:somenumber,
  #    :params=>{'distance'=>5})
  #  mocker.drill
  #  mocker.select('fuel'=>'diesel')
  #  mocker.choices=['large','small']
  #  mocker.drill
  #  lambda{mycalc.choose!('fuel'=>'diesel','banana'=>'large','distance'=>5)}.
  #    should raise_exception Exceptions::NoSuchTerm
  #end

  it 'can be supplied just a UID, and recover PIVs and drill values from AMEE' do
    mycalc=@transport.begin_calculation
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
    mycalc=@transport.begin_calculation
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :result=>:somenumber,
      :existing=>{'distance'=>7},
      :params=>{'distance'=>7},
      :choices=>['petrol','diesel'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.profile_list.get(true,true).delete
    existing_uid=mocker.uid
    mocker.select('size'=>'small')
    mocker.drill.profile_category.timestamp.create_and_get
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
    mycalc=@transport.begin_calculation
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
    mocker.profile_list.profile_category.timestamp.create_and_get

    mocker.existing={'distance'=>5}
    mocker.params={'distance'=>9}
    mocker.update.get(true)

    mycalc=@transport.begin_calculation
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
    mocker.profile_list.profile_category.timestamp.create_and_get.get(true,true).delete

    mocker.select('size'=>'small')
    mocker.drill.create_and_get
    
    mycalc=@transport.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.choose!('fuel'=>'diesel','size'=>'small')
    mycalc.calculate!
    mycalc[:distance].value.should eql 5
  end

  it 'memoizes profile information, but not across a pass' do
    mycalc=@transport.begin_calculation
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :result=>:somenumber,
      :existing=>{'distance'=>5},:choices=>['petrol','diesel'])
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.select('size'=>'large')
    mocker.choices=[]
    mocker.profile_list.update.get(true,false,false)
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
    mocker.profile_list.profile_category.timestamp.create_and_get
    myproto=@transport.clone
    myproto.instance_eval{
      start_and_end_dates
    }
    mycalc=myproto.begin_calculation
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5,'start_date'=>"1976-10-19",'end_date'=>DateTime.parse("2011-1-1"))
    mycalc.calculate!
    mycalc.outputs.first.value.should eql :somenumber
  end

  it 'does not accept start end dates if inappropriate value provided' do
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
    myproto=@transport.clone
    myproto.instance_eval{
      start_and_end_dates
    }
    mycalc=myproto.begin_calculation
    mycalc.choose('fuel'=>'diesel','size'=>'large','distance'=>5,'start_date'=>"banana",'end_date'=>DateTime.parse("2011-1-1")).should be_false
    mycalc.invalidity_messages.keys.should eql [:start_date]
  end

  it 'starts off dirty' do  
    mycalc=@transport.begin_calculation
    mycalc.should be_dirty
  end

  it 'becomes clean when you calculate' do
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
    mocker.profile_list.profile_category.timestamp.create_and_get
    mycalc=@transport.begin_calculation
    mycalc.should be_dirty
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.should_not be_dirty
    mycalc.outputs.first.value.should eql :somenumber
    mycalc.should_not be_dirty
  end

  it 'becomes dirty again if you reset something after you calculate' do
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
    mocker.profile_list.profile_category.timestamp.create_and_get
    mycalc=@transport.begin_calculation
    mycalc.should be_dirty
    mycalc.choose!('fuel'=>'diesel','size'=>'large','distance'=>5)
    mycalc.calculate!
    mycalc.should_not be_dirty
    mycalc.outputs.first.value.should eql :somenumber
    mycalc.should_not be_dirty
    mycalc.choose!('distance'=>7)
    mycalc.should be_dirty
  end

  it 'provides error message and raises exception from choose! if choice invalid' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'marge')
    mocker.choices=[]
    mocker.drill
    mycalc=@transport.begin_calculation
    lambda{mycalc.choose!('fuel'=>'diesel','size'=>'marge','distance'=>5)}.should raise_error Exceptions::ChoiceValidation
    mycalc.invalidity_messages.keys.should eql [:size]
  end

  it 'provides error message and returns false from choose if choice invalid' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'marge')
    mocker.choices=[]
    mocker.drill
    mycalc=@transport.begin_calculation
    mycalc.choose('fuel'=>'diesel','size'=>'marge','distance'=>5).should be_false
    mycalc.invalidity_messages.keys.should eql [:size]
  end

  it 'returns true from choose if choices valid' do
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
    mycalc=@transport.begin_calculation
    mycalc.choose('fuel'=>'diesel','size'=>'large','distance'=>5).should be_true
  end

  it 'can blank individual term attributes with empty string' do
    myproto=@transport.clone
    mycalc=myproto.begin_calculation
    mycalc.choose_without_validation!('fuel'=>'diesel','size'=>'large','distance'=>{:value =>5, :unit=> Unit.km})
    mycalc['fuel'].value.should eql 'diesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 5
    mycalc['distance'].unit.symbol.should eql 'km'
    mycalc.choose_without_validation!('distance'=>{:value =>""})
    mycalc['fuel'].value.should eql 'diesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql ""
    mycalc['distance'].unit.symbol.should eql 'km'
  end

  it 'can blank individual term attributes with nil' do
    myproto=@transport.clone
    mycalc=myproto.begin_calculation
    mycalc.choose_without_validation!('fuel'=>'diesel','size'=>'large','distance'=>{:value =>5, :unit=> Unit.km})
    mycalc['fuel'].value.should eql 'diesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 5
    mycalc['distance'].unit.symbol.should eql 'km'
    mycalc.choose_without_validation!('distance'=>{:value =>nil})
    mycalc['fuel'].value.should eql 'diesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should be_nil
    mycalc['distance'].unit.symbol.should eql 'km'
  end

    it 'can update individual term attributes without nullifying others' do
    myproto=@transport.clone
    mycalc=myproto.begin_calculation
    mycalc.choose_without_validation!('fuel'=>'diesel','size'=>'large','distance'=>{:value =>5, :unit=> Unit.km})
    mycalc['fuel'].value.should eql 'diesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 5
    mycalc['distance'].unit.symbol.should eql 'km'
    mycalc.choose_without_validation!('fuel'=>'biodiesel')
    mycalc['fuel'].value.should eql 'biodiesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 5
    mycalc['distance'].unit.symbol.should eql 'km'
    mycalc.choose_without_validation!('distance'=>{:value =>25})
    mycalc['fuel'].value.should eql 'biodiesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 25
    mycalc['distance'].unit.symbol.should eql 'km'
    mycalc.choose_without_validation!('distance'=>{:unit =>Unit.mi})
    mycalc['fuel'].value.should eql 'biodiesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 25
    mycalc['distance'].unit.symbol.should eql 'mi'
    mycalc.choose_without_validation!('distance'=>{:value=>250,:unit =>Unit.ft})
    mycalc['fuel'].value.should eql 'biodiesel'
    mycalc['size'].value.should eql 'large'
    mycalc['distance'].value.should eql 250
    mycalc['distance'].unit.symbol.should eql 'ft'
  end

  it 'clears invalid terms' do
    mocker=AMEEMocker.new(self,:path=>'transport/car/generic',
      :choices=>['diesel','petrol'],
      :result=>:somenumber,
      :params=>{'distance'=>5})
    mocker.drill
    mocker.select('fuel'=>'diesel')
    mocker.choices=['large','small']
    mocker.drill
    mocker.select('size'=>'marge')
    mocker.choices=[]
    mocker.drill
    mycalc=@transport.begin_calculation
    mycalc.choose('fuel'=>'diesel','size'=>'marge','distance'=>5).should be_false
    mycalc.invalidity_messages.keys.should eql [:size]
    mycalc[:size].value.should eql 'marge'
    mycalc.clear_invalid_terms!
    mycalc.invalidity_messages.keys.should be_empty
    mycalc[:size].value.should be_nil
  end

end

