require 'spec_helper'

describe ActiveSupport::OrderedHash do
  it 'Can insert at start' do
    x=ActiveSupport::OrderedHash[[[1,2],[3,4]]]
    x.keys.should eql [1,3]
    x.insert_at_start(5,6)
    x.keys.should eql [5,1,3]
    x.to_a.should eql [[5,6],[1,2],[3,4]]
  end
end
