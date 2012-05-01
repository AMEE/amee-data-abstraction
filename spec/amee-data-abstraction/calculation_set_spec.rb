require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
class CalculationSet
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  def self.called
    @@called
  end
end
describe CalculationSet do
  it 'can create an instance' do
    ElectricityAndTransport.should be_a CalculationSet
  end
  it 'can create an instance' do
    ElectricityAndTransport.calculations.should be_a ActiveSupport::OrderedHash
  end
  it 'can access a calculation by key' do
    ElectricityAndTransport[:transport].should be_a PrototypeCalculation
  end
  it 'can construct a calculation' do
    CalculationSet.new {calculation {label :mycalc}}[:mycalc].should be_a PrototypeCalculation
  end
  it 'can be initialized with a DSL block' do
    CalculationSet.new {call_me}
    CalculationSet.called.should be_true
  end
  it 'can have terms added to all calculations' do
    cs=CalculationSet.new {
      all_calculations {
        drill {label :energetic}
      }
      calculation {
        label :mycalc
        drill {label :remarkably}
      }
    }
    cs[:mycalc].drills.labels.should eql [:remarkably,:energetic]
  end
  it 'can make multiple calculations quickly, one for each usage' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.usages(['bybob','byfrank']).
      item_definition.data_category.
      item_value_definition('first',['bybob'],[], ['byfrank'],[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('second',['bybob'],[],['byfrank'],[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('third',['byfrank'],[],['bybob'],[],nil,nil,true,false,nil,"TEXT")
    cs=CalculationSet.new {
      calculations_all_usages('/something') { |usage|
        label usage.to_sym
        profiles_from_usage usage
      }
    }
    cs[:bybob].profiles.labels.should eql [:first,:second]
    cs[:byfrank].profiles.labels.should eql [:third]
  end
end