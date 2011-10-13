require 'spec_helper'

describe "AMEE units" do
  
  include Quantify

  # The Unit.<unit_name_symbol_or_label> pattern retrieves the unit which is
  # provided as the (pseudo) method name (using #method_missing). In cases where
  # the named unit does not exist an error is raised. In some cases, however,
  # where the unit can be constructed from a known and compatible unit and prefix
  # combination, it is created but not loaded to the canonical system of units.
  # Therefore, to test for presence or absence of partiuclar units, we check that
  # the units we want are #loaded? and that the ones we don't want are either NOT
  # #loaded? (if the happen to be derivable) or otherwise raise an error.

  it "should include commonly used SI units" do
    Unit.metre.should be_loaded
    Unit.second.should be_loaded
    Unit.kg.should be_loaded
  end

  it "should include commonly used non SI units" do
    Unit.foot.should be_loaded
    Unit.pound.should be_loaded
    Unit.month.should be_loaded
  end

  it "should exclude uncommonly used SI units" do
    Unit.micrometre.should_not be_loaded
    lambda{Unit.galileo}.should raise_error
    lambda{Unit.inverse_centimetre}.should raise_error
  end

  it "should exclude uncommonly used non SI units" do
    lambda{Unit.astronomical_unit}.should raise_error
    lambda{Unit.dyne_centimetre}.should raise_error
    lambda{Unit.maxwell}.should raise_error
  end

  it "should include commonly used SI units and prefixes" do
    Unit.terajoule.should be_loaded
    Unit.gigagram.should be_loaded
    Unit.megawatt.should be_loaded
  end

  it "should include commonly used Non SI units and prefixes" do
    Unit.MBTU.should be_loaded
  end

  it "should exclude uncommonly used SI units and prefixes" do
    Unit.microjoule.should_not be_loaded
    Unit.nanogram.should_not be_loaded
    Unit.picowatt.should_not be_loaded
  end

  it "should represent the BTU with the 59F version" do
    Unit.BTU.label.should eql "BTU_FiftyNineF"
  end

  it "should label the unit for 'day' as 'day'" do
    Unit.day.label.should eql 'day'
  end

  it "should recognise the unit for megawatt_hour as 'MWh'" do
    Unit.megawatt_hour.label.should eql 'MWh'
    Unit.megawatt_hour.symbol.should eql 'MWh'
  end

end

