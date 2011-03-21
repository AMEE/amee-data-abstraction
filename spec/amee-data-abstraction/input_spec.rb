require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'



describe Input do
 it 'can be given a fixed value' do
   i=Input.new{fixed 6}
   i.value.should eql 6
   i.fixed?.should be_true
   lambda{i.value 7}.should raise_error Exceptions::FixedValueInterference
 end
 it 'wipes its value unless valid' do
   i=Input.new{validation /bark/}
   i.value 'barking'
   i.validate!
   i.value.should eql 'barking'
   i.value 'marking'
   i.validate!
   i.value.should eql nil
   j=Input.new{}
   j.value 'marking'
   j.value.should eql 'marking'
 end
end