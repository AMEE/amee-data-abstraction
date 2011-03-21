require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Drill do
  it 'knows its options when it is the first choice' do
    drill_mocks
    Transport.begin_calculation[:fuel].options_for_select.should eql [nil,'diesel','petrol']
  end
  it 'cannot find out its choices if earlier drills are not set' do
    drill_mocks
    lambda{Transport.begin_calculation[:size].options_for_select}.should raise_error Exceptions::EntryOrderException
  end
end