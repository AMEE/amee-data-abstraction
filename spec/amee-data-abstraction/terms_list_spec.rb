require 'spec_helper'

describe TermsList do
  it 'should be returned from calculations' do
    Transport.terms.should be_a TermsList
  end
  it 'should give properties' do
    Transport.terms.labels.should eql [:fuel,:size,:distance,:co2]
    Transport.terms.paths.should eql ['fuel','size','distance',:default]
    Transport.terms.names.should eql ['Fuel Type','Vehicle Size','Distance Driven','Carbon Dioxide']
  end
  it 'should select by class' do
    Transport.terms.drills.labels.should eql [:fuel,:size]
    Transport.terms.profiles.labels.should eql [:distance]
    Transport.terms.outputs.labels.should eql [:co2]
  end
  it 'should select by property' do
    t=Transport.begin_calculation
    t[:distance].value 5
    t.terms.set.labels.should eql [:distance]
    t.terms.unset.labels.should eql [:fuel,:size,:co2]
  end
  it 'should select by chain' do
    t=Transport.begin_calculation
    t[:fuel].value 'diesel'
    t.terms.drills.set.labels.should eql [:fuel]
    t.terms.drills.unset.labels.should eql [:size]
    t.terms.set.drills.labels.should eql [:fuel]
    t.terms.unset.drills.labels.should eql [:size]
  end
  it 'should select by order' do
    t=Transport.clone
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
    t=Transport.clone
    t.profiles.compulsory('usage1').labels.should eql [:distance]
    t.profiles.optional('usage2').labels.should eql [:distance]
    t.profiles.compulsory('usage2').labels.should be_empty
    t.profiles.optional('usage1').labels.should be_empty
    t.profiles.in_use('usage2').labels.should eql [:distance]
    t.profiles.in_use('usage1').labels.should eql [:distance]
    t.profiles.in_use('usage3').labels.should be_empty
  end
 
end