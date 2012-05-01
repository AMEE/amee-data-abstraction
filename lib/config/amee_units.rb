# encoding: UTF-8
# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.
require 'quantify'

Quantify::Unit.configure do

  # Remove from the system of known units, the units which are not used or not
  # anticipated to be useful for interacting with AMEE. These either represent
  # physical quantities which are not typically represented in emissions
  # calculations (e.g. redioactivity, thermal resistance) or units which do
  # represent appropriate physical quantities but are relatively obscure or
  # inappropriate (e.g angstrom, calorie, cup, light year).
  #
  # Note: although AMEE supports 8 types of British thermal unit, only one is
  # made available since it is unlikely that users would like to choose between
  # each of the alternatives.

  required_units = [ "1",
                     "Hz",
                     "Ohm",
                     "V",
                     "m/s",
                     "m/s²",
                     "A",
                     "K",
                     "m",
                     "mol",
                     "s",
                     "kg",
                     "g",
                     "km",
                     "m³",
                     "J",
                     "N",
                     "W",
                     "Pa",
                     "m²",
                     "atm",
                     "bar",
                     "ha",
                     "L",
                     "bbl",
                     "oz_fl_uk",
                     "gal_uk",
                     "gallon_dry_us",
                     "oz_fl",
                     "bbl_fl_us",
                     "gal",
                     "kWh",
                     "°C",
                     "°F",
                     "°R",
                     "ft",
                     "h",
                     "in",
                     "mi",
                     "min",
                     "month",
                     "nmi",
                     "oz",
                     "lb",
                     "t",
                     "week",
                     "yd",
                     "year",
                     "BTU_FiftyNineF",
                     "ton_us",
                     "ton_uk",
                     "d",
                     "lbmol"]

  uneeded_units = []

  units.each do |unit|
    uneeded_units << unit.label unless required_units.include?(unit.label)
  end

  unload(uneeded_units)

end

Quantify::Unit::SI.configure do

  # Load the commonly used SI unit/prefix combinations which are used in AMEE
  prefix_and_load [:mega,:giga], :gram
  prefix_and_load [:mega,:giga,:tera], :joule
  prefix_and_load [:kilo,:mega], :watt

end

Quantify::Unit::Prefix::NonSI.configure do

  # define the nonconventional 'M' (million) prefix which is used with British
  # thermal units. This is similar, but distinct to the SI mega- prefix
  load :name => 'million ', :symbol => 'M', :factor => 1e6

end

Quantify::Unit::NonSI.configure do

  # Give the remaining (default) British thermal unit version a humanised name
  # and symbol
  Unit.BTU_FiftyNineF.configure_as_canonical do |unit|
    unit.name = 'british thermal unit'
    unit.symbol = 'BTU'
  end

  # Differentiate long and short ton symbols
  Unit.ton_us.configure_as_canonical do |unit|
    unit.symbol = 'ton (US)'
  end

  Unit.ton_uk.configure_as_canonical do |unit|
    unit.symbol = 'ton (UK)'
  end

  # AMEE uses 'day' rather than 'd' as the label for the time period, day
  Unit.day.canonical_label = 'day'

  # Load prefixed version of British thermal unit, which is used in AMEE
  prefix_and_load :M, :BTU_FiftyNineF

  # Define and load the megawatt hour, an energy unit used in AMEE
  construct_and_load(megawatt*hour) do |unit|
    unit.symbol = 'MWh'
    unit.label = 'MWh'
  end
  
end