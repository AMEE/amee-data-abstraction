require 'spec_helper'

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
 it "can accept a numeric symbol validation" do
   i=Input.new{validation :numeric}
   i.value 3
   lambda{i.validate!}.should_not raise_error
   i.value '3'
   lambda{i.validate!}.should_not raise_error
   i.value 'e'
   lambda{i.validate!}.should raise_error Exceptions::ChoiceValidation
 end
 it "can accept a date symbol validation" do
   i=Input.new{validation :date}
   i.value Date.today
   lambda{i.validate!}.should_not raise_error
   i.value '2011-01-01'
   lambda{i.validate!}.should_not raise_error
   i.value 'e'
   lambda{i.validate!}.should raise_error Exceptions::ChoiceValidation
 end

 it "can accept a time symbol validation" do
   i=Input.new{validation :datetime}
   i.value DateTime.now
   lambda{i.validate!}.should_not raise_error
   i.value '2011-01-01 09:00:00'
   lambda{i.validate!}.should_not raise_error
   i.value 'e'
   lambda{i.validate!}.should raise_error Exceptions::ChoiceValidation
 end
 it 'can have custom validation message' do
   i=Input.new{label :woof; validation /bark/; validation_message {"#{value} does not match pattern /bark/"}}
   i.value 'marking'
   lambda{i.validate!}.should raise_error Exceptions::ChoiceValidation,"marking does not match pattern /bark/"
   j=Input.new{}
   j.value 'marking'
   j.value.should eql 'marking'
 end
 it 'can have default validation message' do
   i=Input.new{label :woof; validation /bark/}
   i.value 'barking'
   lambda{i.validate!}.should_not raise_error
   i.value.should eql 'barking'
   i.value 'marking'
   lambda{i.validate!}.should raise_error Exceptions::ChoiceValidation,"Woof is invalid."
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