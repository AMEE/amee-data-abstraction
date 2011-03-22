require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Drill do
  it 'knows its options when it is the first choice' do
    drill_mocks
    Transport.begin_calculation[:fuel].options_for_select.should eql [nil,'diesel','petrol']
  end
end