require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Metadatum do
 it 'defaults to be a drop-down' do
   Metadatum.new.drop_down?.should be_true
 end
 it 'can have choices specified' do
   Metadatum.new { choices %w{bob frank}}.choices.should eql ['bob','frank']
 end
 it 'validates on choices' do
   m=Metadatum.new { choices %w{bob frank}}
   m.value 'bob'
   m.should be_valid
   m.value 'mark'
   m.should_not be_valid
 end
end