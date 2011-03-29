require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
class PrototypeCalculation
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  cattr_accessor :called
end
describe PrototypeCalculation do
  it 'can create an instance' do
    Transport.should be_a PrototypeCalculation
  end
  it 'can be initialized with a DSL block' do
    PrototypeCalculation.new {call_me}
    PrototypeCalculation.called.should be_true
  end
  it 'can make a drill in the DSL block' do
    pc=PrototypeCalculation.new {drill{label :alpha}}
    pc[:alpha].should be_a Drill
  end
  it 'can''t make a DSL block term without a label' do
    lambda{
      pc=PrototypeCalculation.new {drill}
    }.should raise_error Exceptions::DSL
  end
  it 'can make a profile item value in the DSL block' do
    pc=PrototypeCalculation.new {profile{label :alpha}}
    pc[:alpha].should be_a Profile
  end
  it 'can make an output in the DSL block' do
    pc=PrototypeCalculation.new {output{label :alpha}}
    pc[:alpha].should be_a Output
  end
  it 'can construct an ongoing calculation' do
    Transport.begin_calculation.should be_a OngoingCalculation
  end
  it 'should make the terms of the ongoing calculation be their own instances' do
    oc=Transport.begin_calculation
    oc[:distance].value :somevalue
    oc[:distance].value.should eql :somevalue
    Transport[:distance].value.should be_nil
  end
  it 'should copy name, path, label when cloning ongoing' do
    [:path,:name,:label].each do |property|
      Transport.begin_calculation.send(property).should eql Transport.send(property)
    end
  end
  it 'can autogenerate drill terms for itself, based on talking to amee' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.itemdef_drills ['first','second','third']
    mocker.item_definition.data_category
    pc=PrototypeCalculation.new {path '/something'; all_drills}
    pc.drills.labels.should eql [:first,:second,:third]
  end
  it 'can autogenerate profile terms for itself' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first').
      item_value_definition('second').
      item_value_definition('third')
    pc=PrototypeCalculation.new {path '/something'; all_profiles}
    pc.profiles.labels.should eql [:first,:second,:third]
  end
  it 'can autogenerate profile terms for itself, based on a usage' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob']).
      item_value_definition('second',['bybob']).
      item_value_definition('third',[],[],['bybob'])
    pc=PrototypeCalculation.new {path '/something'; profiles_from_usage('bybob')}
    pc.profiles.labels.should eql [:first,:second]
  end
  it 'can select terms by usage with a longer list' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],'byfrank').
      item_value_definition('second',['bybob'],[],'byfrank').
      item_value_definition('third',['byfrank'],[],['bybob'])
    pc=PrototypeCalculation.new {path '/something'; all_profiles ; fixed_usage 'bybob'}
    pc.profiles.in_use.labels.should eql [:first,:second]
    pc.profiles.out_of_use.labels.should eql [:third]
    pc.fixed_usage 'byfrank'
    pc.profiles.out_of_use.labels.should eql [:first,:second]
    pc.profiles.in_use.labels.should eql [:third]
  end
  it 'can generate itself with dynamic usage dropdown' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],'byfrank').
      item_value_definition('second',['bybob'],[],'byfrank').
      item_value_definition('third',['byfrank'],[],['bybob'])
    pc=PrototypeCalculation.new {path '/something'; usage{ value 'bybob'}}
    pc.profiles.labels.should eql [:first,:second,:third]
    pc.profiles.visible.labels.should eql [:first,:second]
    pc.terms.labels.should eql [:usage,:first,:second,:third]
  end
end

