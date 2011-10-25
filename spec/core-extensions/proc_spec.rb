require 'spec_helper'

describe Proc do
  before :all do
    @it=Proc.new{|x|x.is_a? Float}
  end
 it 'uses call as ===' do
  (@it===3.4).should be_true
  (@it===7).should be_false
  (@it==='hello').should be_false
 end
end
