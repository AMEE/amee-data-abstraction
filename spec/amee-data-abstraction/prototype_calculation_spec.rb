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
end

