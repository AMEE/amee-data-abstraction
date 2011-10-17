require 'spec_helper'

describe Calculation do
  
  before :all do
    @calc = CalculationSet.find("transport")[:transport]
  end
  
  it 'can create an instance' do
    @calc.should be_a Calculation
  end
  it 'should have ordered terms, with labels' do
    @calc.terms.labels.should eql [:fuel,:size,:distance,:co2]
  end
  it 'should have amee paths for the terms' do
    @calc.terms.paths.should eql ['fuel','size','distance','default']
  end
  it 'should have human names for the terms' do
    @calc.terms.names.
      should eql ['Fuel Type','Vehicle Size','Distance Driven','Carbon Dioxide']
  end
  it 'should return the inputs' do
    @calc.inputs.labels.should  eql [:fuel,:size,:distance]
  end
  it 'should return the outputs' do
    @calc.outputs.labels.should  eql [:co2]
  end
  it 'should generate an discover URL' do
    @calc.discover_url.should eql 'http://discover.amee.com/categories/transport/car/generic'
  end
  it 'should redirect to discover URL' do
    @calc.explorer_url.should eql 'http://discover.amee.com/categories/transport/car/generic'
  end
  it 'can return a term via []' do
    @calc[:co2].label.should eql :co2
  end
  it 'when copied, should deep copy the values' do
    x=@calc.clone
    x[:co2].value :somevalue
    x[:co2].value.should eql :somevalue
    @calc[:co2].value.should be_nil
  end
  it 'knows to get terms that come before or after others' do
    t=@calc.clone
    t.before(:distance).labels.
      should eql [:fuel,:size]
    t.after(:distance).map(&:label).
      should eql [:co2]
  end
  it 'delegates selectors to terms list' do
    t=@calc.clone
    t.drills.labels.should eql [:fuel,:size]
  end
  it 'can find its amee data category' do
    t=@calc.clone
    mocker=AMEEMocker.new self,:path=>'transport/car/generic'
    mocker.data_category
    t.send(:amee_data_category).path.should eql '/data/transport/car/generic'
  end
  it 'can find its amee item definition' do
    mocker=AMEEMocker.new self,:path=>'transport/car/generic'
    mocker.item_definition(:my_itemdef_name).data_category
    t=@calc.clone
    t.send(:amee_item_definition).name.should eql :my_itemdef_name
  end
  it 'can give item value definition list' do
    mocker=AMEEMocker.new self,:path=>'transport/car/generic'
    mocker.item_value_definition('distance').item_value_definitions.
      item_definition.data_category
    t=@calc.clone
    t.send(:amee_ivds).first.path.should eql 'distance'
  end
  it 'can memoise access to  AMEE' do
    t=@calc.clone
    #AMEE::Data::Category.get(connection, "/data#{path}")
    flexmock(AMEE::Data::Category).should_receive(:get).
      with(AMEE::DataAbstraction.connection,'/data/transport/car/generic').
      once.and_return(true)
    t.send(:amee_data_category)
    t.send(:amee_data_category)
  end
end

