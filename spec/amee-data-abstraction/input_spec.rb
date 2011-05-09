require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Input do
 it 'can be given a fixed value' do
   i=Input.new{fixed 6}
   i.value.should eql 6
   i.fixed?.should be_true
   lambda{i.value 7}.should raise_error Exceptions::FixedValueInterference
 end
 it 'raises exception when invalid' do
   i=Input.new{validation /bark/}
   i.value 'barking'
   lambda{i.validate!}.should_not raise_error
   i.value.should eql 'barking'
   i.value 'marking'
   lambda{i.validate!}.should raise_error Exceptions::ChoiceValidation
   j=Input.new{}
   j.value 'marking'
   j.value.should eql 'marking'
 end
 it 'is always valid if it is fixed' do
   i=Input.new{fixed 5; validation /7/}
   lambda{i.validate!}.should_not raise_error
   i.value.should eql 5
 end
 it 'is always disabled if it is fixed' do
   i=Input.new{fixed 5}
   i.disabled?.should eql true
 end
end