require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
class CalculationSet
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  cattr_accessor :called
end
describe CalculationSet do
  it 'can create an instance' do
    ElectricityAndTransport.should be_a CalculationSet
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
end