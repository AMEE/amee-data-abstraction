require 'spec_helper'

class Term
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  def self.called
    @@called
  end
end

describe Term do

  before :all do
    @calc = CalculationSet.find("transport")[:transport]
  end

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

  it "has note" do
    Term.new {note 'hello'}.note.should eql 'hello'
  end

  it "has note with no '\"' character" do
     Term.new {note 'hello "some quote"'}.note.should eql "hello 'some quote'"
  end

  it 'has parent' do
    @calc[:distance].parent.should eql @calc
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
    @calc.terms.
      select{|x|x.before?(:distance)}.map(&:label).
      should eql [:fuel,:size]
    @calc.terms.
      select{|x|x.after?(:distance)}.map(&:label).
      should eql [:co2]
  end

  it "should respond to unit methods" do
    [ "unit", "per_unit", "default_unit", "default_per_unit", "alternative_units", "alternative_per_units" ].each do |meth|
    Term.new.methods.should include meth.to_sym
  end
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

  it "has unit choices which include default and alternative" do
    term = Term.new {path :hello; default_unit :kg; default_per_unit :kWh}
    units = term.alternative_units.map(&:name)
    units.should include "gigagram", "pound", "tonne"
    units.should_not include "kilogram", "kelvin"

    units = term.unit_choices.map(&:name)
    units.first.should eql "kilogram"
    units.should include "kilogram", "gigagram", "pound", "tonne"
    units.should_not include "kelvin"

    per_units = term.alternative_per_units.map(&:name)
    per_units.should include "joule", "british thermal unit", "megawatt hour"
    per_units.should_not include "kilowatt hour"

    per_units = term.per_unit_choices.map(&:name)
    per_units.first.should eql "kilowatt hour"
    per_units.should include "kilowatt hour", "joule", "british thermal unit", "megawatt hour"
  end

  it "has limited set of alternative units if specified" do
    term = Term.new {path :hello; default_unit :kg; alternative_units :t, :ton_us, :lb}
    units = term.alternative_units.map(&:name)
    units.should include "tonne", "pound", "short ton"
    units.should_not include "gigagram", "ounce", "gram"
  end

  it "has unit choices which include default and alternative with limited set of alternative units" do
    term = Term.new {path :hello; default_unit :kg; alternative_units :t, :ton_us, :lb}
    units = term.alternative_units.map(&:name)
    units.should include "tonne", "pound", "short ton"
    units.should_not include "kilogram", "gigagram", "ounce", "gram"

    units = term.unit_choices.map(&:name)
    units.first.should eql "kilogram"
    units.should include "kilogram", "tonne", "pound", "short ton"
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
    Term.new {path :hello; value 12; default_unit :kg}.to_s.should == '12.0 kg'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s.should == '12.0 kg/h'
    Term.new {path :hello; value 12; per_unit :h}.to_s.should == '12.0 h^-1'
  end

  it "should represent term as string with unit label" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s(:label).should == '12.0 kg'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s(:label).should == '12.0 kg/h'
    Term.new {path :hello; value 12; per_unit :h}.to_s(:label).should == '12.0 h^-1'
  end

  it "should represent term as string with unit name" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s(:name).should == '12.0 kilograms'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s(:name).should == '12.0 kilograms per hour'
    Term.new {path :hello; value 12; per_unit :h}.to_s(:name).should == '12.0 per hour'
  end

  it "should represent term as string with unit pluralized name" do
    Term.new {path :hello; value 12; default_unit :kg}.to_s(:pluralized_name).should == '12.0 kilograms'
    Term.new {path :hello; value 12; default_unit :kg; per_unit :h}.to_s(:pluralized_name).should == '12.0 kilograms per hour'
    Term.new {path :hello; value 12; per_unit :h}.to_s(:pluralized_name).should == '12.0 per hour'
  end

  it "should represent term as string with no units" do
    Term.new {path :hello; value 12}.to_s(:pluralized_name).should == '12'
    Term.new {path :hello; value 12}.to_s(:name).should == '12'
    Term.new {path :hello; value 12}.to_s(:symbol).should == '12'
    Term.new {path :hello; value 12}.to_s(:label).should == '12'
    Term.new {path :hello; value 12}.to_s.should == '12'
  end

  it "should be recognised as numeric" do
    Term.new {path :hello; value 12; default_unit :kg}.has_numeric_value?.should be_true
  end

  it "string should be recognised as numeric if type not explicitly declared" do
    Term.new {path :hello; value "12"; default_unit :kg}.has_numeric_value?.should be_true
  end

  it "should be recognised as non numeric" do
    Term.new {path :hello; value 'bob'; default_unit :kg}.has_numeric_value?.should be_false
  end

  it "string should be recognised as non numeric if type declared" do
    Term.new {path :hello; value '12'; default_unit :kg; type :string}.has_numeric_value?.should be_false
  end
  
  it "should convert the input to a String if the type is specified as such" do
    Term.new {type :string; value 54}.value.should == "54"
  end
  
  it "should convert the input to a Fixnum if the type is specified as such" do
    Term.new {type :fixnum; value '54'}.value.should == 54
  end
  
  it "should convert the input to a Float if the type is specified as such" do
    Term.new {type :float; value '54'}.value.should == 54.0
  end
  
  it "should convert the input to a Date if the type is specified as such" do
    Term.new {type :date; value '2011-01-01'}.value.should == Date.parse("2011-01-01")
  end
  
  it "should convert the input to a Time if the type is specified as such" do
    Term.new {type :time; value "2011-01-01 10:00:00"}.value.should == Time.parse("2011-01-01 10:00:00")
  end
  
  it "should convert the input to a DateTime if the type is specified as such" do
    now = DateTime.now
    Term.new {type :datetime; value now.to_s}.value.should === now
  end
  
  it "should store the pre cast value" do
    term = Term.new {type :float; value '54'}
    term.value.should == 54.0
    term.value_before_cast.should == "54"
  end

    it "should return self if no unit or per unit attribute" do
    @term = Term.new { value 20 }
    @term.unit.should be_nil
    @term.per_unit.should be_nil
    @term.value.should eql 20
    new_term = @term.convert_unit(:unit => :t)
    new_term.should === @term
    new_term.value.should eql 20
    new_term.unit.should be_nil
    new_term.per_unit.should be_nil
  end

  it "should return self if not a numeric unit" do
    @term = Term.new { value 'plane'; unit :kg; type :string }
    @term.unit.label.should eql 'kg'
    @term.value.should eql 'plane'
    new_term = @term.convert_unit(:unit => :t)
    new_term.should === @term
  end

  it "should convert unit" do
    @term = Term.new { value 20; unit :kg }
    @term.unit.symbol.should eql 'kg'
    @term.value.should eql 20
    new_term = @term.convert_unit(:unit => :t)
    new_term.unit.symbol.should eql 't'
    new_term.value.should eql 0.020
  end

  it "should convert per unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    new_term = @term.convert_unit(:per_unit => :h)
    new_term.unit.symbol.should eql 'kg'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1200.0
  end

  it "should convert unit and per unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    new_term = @term.convert_unit( :unit => :t, :per_unit => :h )
    new_term.unit.symbol.should eql 't'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1.2000
  end

  it "should convert unit if value a string" do
    @term = Term.new { value "20"; unit :kg }
    @term.unit.symbol.should eql 'kg'
    @term.value.should eql "20"
    new_term = @term.convert_unit(:unit => :t)
    new_term.unit.symbol.should eql 't'
    new_term.value.should eql 0.020
  end

  it "should convert per unit if value a string" do
    @term = Term.new { value "20"; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql "20"
    new_term = @term.convert_unit(:per_unit => :h)
    new_term.unit.symbol.should eql 'kg'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1200.0
  end

  it "should convert unit and per unit if value a string" do
    @term = Term.new { value "20"; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql "20"
    new_term = @term.convert_unit( :unit => :t, :per_unit => :h )
    new_term.unit.symbol.should eql 't'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1.2000
  end

  it "should convert unit if value empty" do
    @term = Term.new { unit :kg }
    @term.unit.symbol.should eql 'kg'
    @term.value.should eql nil
    new_term = @term.convert_unit(:unit => :t)
    new_term.unit.symbol.should eql 't'
    new_term.value.should eql nil
  end

  it "should convert per unit if value empty" do
    @term = Term.new { unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql nil
    new_term = @term.convert_unit(:per_unit => :h)
    new_term.unit.symbol.should eql 'kg'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql nil
  end

  it "should convert unit and per unit if value empty" do
    @term = Term.new { unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql nil
    new_term = @term.convert_unit( :unit => :t, :per_unit => :h )
    new_term.unit.symbol.should eql 't'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql nil
  end

  it "should convert unit if value 0" do
    @term = Term.new { value 0; unit :kg }
    @term.unit.symbol.should eql 'kg'
    @term.value.should eql 0
    new_term = @term.convert_unit(:unit => :t)
    new_term.unit.symbol.should eql 't'
    new_term.value.should eql 0.0
  end

  it "should convert per unit if value 0" do
    @term = Term.new { value 0; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 0
    new_term = @term.convert_unit(:per_unit => :h)
    new_term.unit.symbol.should eql 'kg'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 0.0
  end

  it "should convert unit and per unit if value 0" do
    @term = Term.new { value 0; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 0
    new_term = @term.convert_unit( :unit => :t, :per_unit => :h )
    new_term.unit.symbol.should eql 't'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 0.0
  end

  it "should raise error if trying to convert to non dimensionally equivalent unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    lambda{new_term = @term.convert_unit( :unit => :J, :per_unit => :h )}.should raise_error
  end

  it "should raise error if trying to convert to non dimensionally equivalent unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    lambda{new_term = @term.convert_unit( :unit => :J, :per_unit => :h )}.should raise_error
  end

  describe "quantities" do

    it "should convert term with unit to quantity object" do
      @term = Term.new { value 20; unit :kg }
      quantity = @term.to_quantity
      quantity.unit.name.should eql "kilogram"
      quantity.unit.symbol.should eql "kg"
      quantity.value.should eql 20.0
      quantity.to_s.should eql "20.0 kg"
    end

    it "should convert term with per unit to quantity object" do
      @term = Term.new { value 20; per_unit :h }
      quantity = @term.to_quantity
      quantity.unit.name.should eql "per hour"
      quantity.unit.symbol.should eql "h^-1"
      quantity.value.should eql 20.0
      quantity.to_s.should eql "20.0 h^-1"
    end

    it "should convert term with unit and per unit to quantity object" do
      @term = Term.new { value 20; unit :kg; per_unit :h }
      quantity = @term.to_quantity
      quantity.unit.name.should eql "kilogram per hour"
      quantity.unit.symbol.should eql "kg/h"
      quantity.value.should eql 20.0
      quantity.to_s.should eql "20.0 kg/h"
    end

    it "should return nil with no unit or per unit" do
      @term = Term.new { value 20 }
      quantity = @term.to_quantity
      quantity.should eql 20
      quantity.should be_a Integer
    end

    it "should return nil with non numeric term" do
      @term = Term.new { value "taxi" }
      quantity = @term.to_quantity
      quantity.should be_nil
    end

    it "should convert term with unit to quantity object with alias method" do
      @term = Term.new { value 20; unit :kg }
      quantity = @term.to_q
      quantity.unit.name.should eql "kilogram"
      quantity.unit.symbol.should eql "kg"
      quantity.value.should eql 20.0
      quantity.to_s.should eql "20.0 kg"
    end

    it "should convert term with per unit to quantity object with alias method" do
      @term = Term.new { value 20; per_unit :h }
      quantity = @term.to_q
      quantity.unit.name.should eql "per hour"
      quantity.unit.symbol.should eql "h^-1"
      quantity.value.should eql 20.0
      quantity.to_s.should eql "20.0 h^-1"
    end
  end

  it "should recognise similar terms" do
    @term1 = Term.new { value 20; per_unit :h }
    @term2 = Term.new { value 20; per_unit :h }
    (@term1 == @term2).should be_true
  end

  it "should recognise dissimilar terms" do
    @term1 = Term.new { value 20; per_unit :h }
    @term2 = Term.new { value 40; per_unit :h }
    (@term1 == @term2).should be_false
  end
  
end