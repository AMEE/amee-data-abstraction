require 'spec_helper'

describe TermsList do
  before :all do
    @calc = CalculationSet.find("transport")[:transport]
  end
  
  it 'should be returned from calculations' do
    @calc.terms.should be_a TermsList
  end
  it 'should give properties' do
    @calc.terms.labels.should eql [:fuel,:size,:distance,:co2]
    @calc.terms.paths.should eql ['fuel','size','distance','default']
    @calc.terms.names.should eql ['Fuel Type','Vehicle Size','Distance Driven','Carbon Dioxide']
  end
  it 'should select by class' do
    @calc.terms.drills.labels.should eql [:fuel,:size]
    @calc.terms.profiles.labels.should eql [:distance]
    @calc.terms.outputs.labels.should eql [:co2]
  end
  it 'should select by property' do
    t=@calc.begin_calculation
    t[:distance].value 5
    t.terms.set.labels.should eql [:distance]
    t.terms.unset.labels.should eql [:fuel,:size,:co2]
  end
  it 'should select by chain' do
    t=@calc.begin_calculation
    t[:fuel].value 'diesel'
    t.terms.drills.set.labels.should eql [:fuel]
    t.terms.drills.unset.labels.should eql [:size]
    t.terms.set.drills.labels.should eql [:fuel]
    t.terms.unset.drills.labels.should eql [:size]
  end
  it 'should select by order' do
    t=@calc.clone
    t.terms.before(:distance).labels.
      should eql [:fuel,:size]
    t.terms.after(:distance).labels.
      should eql [:co2]
  end
  it 'can select terms by usage' do
    mocker=AMEEMocker.new self,:path=>'transport/car/generic'
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('distance',['usage1'],['usage2'],['usage3'])
    t=@calc.clone
    t.profiles.compulsory('usage1').labels.should eql [:distance]
    t.profiles.optional('usage2').labels.should eql [:distance]
    t.profiles.compulsory('usage2').labels.should be_empty
    t.profiles.optional('usage1').labels.should be_empty
    t.profiles.in_use('usage2').labels.should eql [:distance]
    t.profiles.in_use('usage1').labels.should eql [:distance]
    t.profiles.in_use('usage3').labels.should be_empty
  end
 
end