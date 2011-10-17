require 'spec_helper'

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
    t=CalculationSet.find(TRANSPORT_CONFIG)[:transport].clone
    t[:distance].compulsory?('someusage').should eql true
    t[:distance].compulsory?('someotherusage').should eql false
    t[:distance].optional?('someotherusage').should eql true
    t[:distance].optional?('someusage').should eql false
  end
  it 'can have choices' do
    i=Profile.new{label :one; choices ['a','b']}
    i.choices.should eql ['a','b']
    i.interface.should eql :drop_down
  end
  it 'must have a chosen choice if it has a choice' do
    i=Profile.new{label :one; choices ['a','b']}
    i.choices.should eql ['a','b']
    i.value 'a'
    i.should be_valid
    i.value 'c'
    i.should_not be_valid
  end
  it 'doesn''t have to have choices' do
    i=Profile.new{label :one}
    i.choices.should be_nil
    i.interface.should eql :text_box
    i.value 'mark'
    i.should be_valid
  end
end