require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

describe Profile do
 it 'defaults to be a text-box' do
   i=Profile.new
   i.text_box?.should be_true
 end
 it 'can know if it belongs to a particular usage' do
    mocker=AMEEMocker.new self,:path=>'transport/car/generic'
    mocker.item_value_definitions.
      item_definition.data_category.
    item_value_definition('distance',['someusage'],['someotherusage'])
    Transport[:distance].compulsory?('someusage').should eql true
    Transport[:distance].compulsory?('someotherusage').should eql false
    Transport[:distance].optional?('someotherusage').should eql true
    Transport[:distance].optional?('someusage').should eql false
  end
end