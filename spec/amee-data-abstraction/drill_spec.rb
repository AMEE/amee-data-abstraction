require 'spec_helper'

describe Drill do
  
  before :all do
    @calc = CalculationSet.find("transport")[:transport]
  end

  it 'knows its options when it is the first choice' do
    AMEEMocker.new(self,:path=>'transport/car/generic',
      :selections=>[],
      :choices=>['diesel','petrol']).drill
    @calc.begin_calculation[:fuel].send(:choices).should eql ['diesel','petrol']
  end

  it 'knows its options when it is a later choice' do
    AMEEMocker.new(self,:path=>'transport/car/generic',
      :selections=>[['fuel','diesel']],
      :choices=>['large','small']).drill
    t=@calc.begin_calculation
    t[:fuel].value 'diesel'
    t[:size].send(:choices).should eql ['large','small']
  end
  
  it 'is enabled iff it is the next choice or has been chosen' do
    t=@calc.begin_calculation
    t[:fuel].enabled?.should be_true
    t[:size].enabled?.should be_false
    t[:fuel].value 'diesel'
    t[:fuel].enabled?.should be_true
    t[:size].enabled?.should be_true
    t[:size].value 'large'
    t[:fuel].enabled?.should be_true
    t[:size].enabled?.should be_true
  end

  it 'is valid if assigned a choice in the choices' do
    AMEEMocker.new(self,:path=>'transport/car/generic',
      :selections=>[],
      :choices=>['diesel','petrol']).drill
    t=@calc.begin_calculation
    t[:fuel].value 'diesel'
    t[:fuel].send(:valid?).should be_true
    t[:fuel].value 'banana'
    t[:fuel].send(:valid?).should be_false
  end

  it "should set and get custom choices" do
    t=@calc.begin_calculation
    t[:fuel].choices 'anthracite', 'lignite'
    t[:fuel].choices.should eql ['anthracite', 'lignite']
  end

  it 'is sets correct single choice if AMEE skips during drill' do
    mocker = AMEEMocker.new(self,:path=>'transport/car/generic',
      :selections=>[['fuel','diesel']])
    mocker.drill_with_skip('size'=>'small')
    t=@calc.begin_calculation
    t[:fuel].value 'diesel'
    t[:fuel].should_not be_disabled
    t[:size].choices.should eql ['small']
    t[:size].should be_disabled
  end
end