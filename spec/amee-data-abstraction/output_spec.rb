require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Profile do
 it 'defaults to be a text-box' do
   i=Profile.new
   i.text_box?.should be_true
 end
end