require File.dirname(File.dirname(__FILE__)) + '/spec_helper.rb'

class Term
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  cattr_accessor :called
end

describe Term do
  it 'can be initialized via DSL block' do
    Term.new {call_me}
    Term.called.should be_true
  end
  it "has label" do
    Term.new {label :hello}.label.should eql :hello
  end
  it "has name" do
    Term.new {name :hello}.name.should eql :hello
  end
  it "has path" do
    Term.new {path :hello}.path.should eql :hello
  end
  it 'has parent' do
    Transport[:distance].parent.should eql Transport
  end
  it "has name defaulting to label" do
    Term.new {label :hello}.name.should eql 'Hello'
    Term.new {label :hello ; name 'goodbye'}.name.should eql 'goodbye'
    Term.new {name 'goodbye' ; label :hello }.name.should eql 'goodbye'
  end
  it 'has path defaulting to label' do
    Term.new {label :hello}.path.should eql 'hello'
    Term.new {label :hello ; path 'goodbye'}.path.should eql 'goodbye'
    Term.new {path 'goodbye' ; label :hello }.path.should eql 'goodbye'
  end
  it 'has value' do
    Term.new {value :hello}.value.should eql :hello
  end
  it 'knows if it is set' do
    Term.new {value :hello}.set?.should be_true
    Term.new.set?.should be_false
  end
  it 'has interface' do
    Term.new {interface :text_box}.interface.should eql :text_box
  end
  it 'raises exception on invalid interface' do
    lambda{Term.new {interface :bobby}}.should raise_error Exceptions::InvalidInterface
  end
  it 'knows what it''s interface is' do
    Term.new {interface :text_box}.text_box?.should be_true
    Term.new {interface :text_box}.drop_down?.should be_false
    Term.new {interface :drop_down}.text_box?.should be_false
    Term.new {interface :drop_down}.drop_down?.should be_true
  end
  it 'can be enabled or disabled' do
    t=Term.new
    t.enabled?.should be_true
    t.disabled?.should be_false
    t.disable!
    t.enabled?.should be_false
    t.disabled?.should be_true
    t.enable!
    t.enabled?.should be_true
    t.disabled?.should be_false
  end
  it 'can be visible or invisible' do
    t=Term.new
    t.visible?.should be_true
    t.hidden?.should be_false
    t.hide!
    t.visible?.should be_false
    t.hidden?.should be_true
    t.show!
    t.visible?.should be_true
    t.hidden?.should be_false
  end
  it 'knows which terms come before or after it' do
    Transport.terms.values.
      select{|x|x.before?(:distance)}.map(&:label).
      should eql [:fuel,:size]
    Transport.terms.values.
      select{|x|x.after?(:distance)}.map(&:label).
      should eql [:co2]
  end
end