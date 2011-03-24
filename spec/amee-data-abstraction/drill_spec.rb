require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'
describe Drill do
  it 'knows its options when it is the first choice' do
    mock_amee(
    'transport/car/generic'=> [
      [{},['diesel','petrol']]
    ])
    Transport.begin_calculation[:fuel].options_for_select.should eql [nil,'diesel','petrol']
  end
  it 'knows its options when it is a later choice' do
    mock_amee('transport/car/generic'=> [
      [[['fuel','diesel']],['large','small']]])
    t=Transport.begin_calculation
    t[:fuel].value 'diesel'
    t[:size].options_for_select.should eql [nil,'large','small']
  end
  it 'is enabled iff it is the next choice or has been chosen' do
    t=Transport.begin_calculation
    t[:fuel].enabled?.should be_true
    t[:size].enabled?.should be_false
    t[:fuel].value 'diesel'
    t[:fuel].enabled?.should be_true
    t[:size].enabled?.should be_true
    t[:size].value 'large'
    t[:fuel].enabled?.should be_true
    t[:size].enabled?.should be_true
  end
  it 'is valid iff assigned a choice in the choices' do
    mock_amee(
    'transport/car/generic'=> [
      [[],['diesel','petrol']],
    ])
    t=Transport.begin_calculation
    t[:fuel].value 'diesel'
    t[:fuel].send(:valid?).should be_true
    t[:fuel].value 'banana'
    t[:fuel].send(:valid?).should be_false
  end
end