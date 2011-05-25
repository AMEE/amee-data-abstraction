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
    Transport.terms.
      select{|x|x.before?(:distance)}.map(&:label).
      should eql [:fuel,:size]
    Transport.terms.
      select{|x|x.after?(:distance)}.map(&:label).
      should eql [:co2]
  end

  it "should respond to unit methods" do
    Term.new.methods.should include "unit","per_unit","default_unit","default_per_unit",
                                    "alternative_units","alternative_per_units"
  end

  it "has no default unit if none declared" do
    Term.new {path :hello}.default_unit.should be_nil
    Term.new {path :hello}.default_per_unit.should be_nil
    Term.new {path :hello}.unit.should be_nil
    Term.new {path :hello}.per_unit.should be_nil
  end

  it "has default unit if specified" do
    Term.new {path :hello; default_unit :kg}.default_unit.name.should == 'kilogram'
    Term.new {path :hello; default_per_unit :kWh}.default_per_unit.pluralized_name.should == 'kilowatt hours'
    Term.new {path :hello; default_unit :kg}.default_unit.should be_a Quantify::Unit::SI
  end

  it "has current unit defaulting to default unit if none specified" do
    Term.new {path :hello; default_unit :kg}.unit.name.should == 'kilogram'
    Term.new {path :hello; default_per_unit :kWh}.per_unit.pluralized_name.should == 'kilowatt hours'
    Term.new {path :hello; default_unit :kg}.unit.should be_a Quantify::Unit::SI
  end

  it "should have no alternative units if none specified and no default" do
    term = Term.new {path :hello}
    term.default_unit.should be_nil
    term.unit.should be_nil
    term.default_per_unit.should be_nil
    term.per_unit.should be_nil
    term.alternative_units.should be_nil
    term.alternative_per_units.should be_nil
  end

  it "has default unit alternatives if none specified" do
    term = Term.new {path :hello; default_unit :kg; default_per_unit :kWh}
    units = term.alternative_units.map(&:name)
    units.should include "gigagram", "pound", "tonne"
    per_units = term.alternative_per_units.map(&:name)
    per_units.should include "joule", "british thermal unit", "megawatt hour"
  end

  it "has limited set of alternative units if specified" do
    term = Term.new {path :hello; default_unit :kg; alternative_units :t, :ton_us, :lb}
    units = term.alternative_units.map(&:name)
    units.should include "tonne", "pound", "short ton"
    units.should_not include "gigagram", "ounce", "gram"
  end

  it "should raise error when specifying incompatible alternative units" do
    lambda{Term.new {path :hello; default_unit :kg; alternative_units :kWh, :km}}.should raise_error
  end

  it "should make a clone" do
    term = Term.new {path :hello; default_unit :kg; alternative_units :t, :ton_us, :lb}
    term.path.should eql :hello
    term.default_unit.should be_a Quantify::Unit::Base
    original_unit_instance = term.default_unit
    term.default_unit.symbol.should eql 'kg'
    new_term = term.clone
    new_term.path.should eql :hello
    new_term.default_unit.should be_a Quantify::Unit::Base
    new_term.default_unit.symbol.should eql 'kg'
    new_unit_instance = new_term.default_unit
    original_unit_instance.should_not eql new_unit_instance
  end

  it "should represent term as string with unit symbol if no argument provided" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s.should == '12 kg'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s.should == '12 kg h^-1'
    Term.new {path :hello; value 12; per_unit :h}.to_s.should == '12 h^-1'
  end

  it "should represent term as string with unit label" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s(:label).should == '12 kg'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s(:label).should == '12 kg/h'
    Term.new {path :hello; value 12; per_unit :h}.to_s(:label).should == '12 h^-1'
  end

  it "should represent term as string with unit name" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s(:name).should == '12 kilogram'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s(:name).should == '12 kilogram per hour'
    Term.new {path :hello; value 12; per_unit :h}.to_s(:name).should == '12 per hour'
  end

  it "should represent term as string with unit pluralized name" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s(:pluralized_name).should == '12 kilograms'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s(:pluralized_name).should == '12 kilograms per hour'
    Term.new {path :hello; value 12; per_unit :h}.to_s(:pluralized_name).should == '12 per hour'
  end
end