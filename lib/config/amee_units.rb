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
  
  unload [ :inverse_centimetre,
           :galileo,
           :micrometre,
           :centiradian,
           :acre,
           :angstrom,
           :arcminute,
           :arcsecond,
           :are,
           :astronomical_unit,
           :barn,
           :biot,
           :BTU_IT,
           :BTU_ThirtyNineF,
           :BTU_Mean,
           :BTU_ISO,
           :BTU_SixtyF,
           :BTU_SixtyThreeF,
           :BTU_Thermochemical,
           :bushel_uk,
           :bushel_us,
           :byte,
           :calorie,
           :candle_power,
           :carat,
           :celsius_heat_unit,
           :centimetre_of_mercury,
           :centimetre_of_water,
           :chain,
           :cup,
           :sidereal_day,
           :degree,
           :dram,
           :dyne,
           :dyne_centimetre,
           :electron_mass,
           :electron_volt,
           :erg,
           :ell,
           :faraday,
           :fathom,
           :fermi,
           :us_survey_foot,
           :franklin,
           :foot_of_water,
           :footcandle,
           :furlong,
           :gamma,
           :gauss,
           :uk_gill,
           :us_gill,
           :grad,
           :grain,
           :hartree,
           :hogshead,
           :boiler_horsepower,
           :electric_horsepower,
           :metric_horsepower,
           :uk_horsepower,
           :hundredweight_long,
           :hundredweight_short,
           :inch_of_mercury,
           :inch_of_water,
           :kilocalorie,
           :kilogram_force,
           :knot,
           :lambert,
           :nautical_league,
           :statute_league,
           :light_year,
           :line,
           :link,
           :maxwell,
           :millibar,
           :millimetre_of_mercury,
           :point,
           :parsec,
           :pennyweight,
           :poncelot,
           :poundal,
           :pound_force,
           :quad,
           :rad,
           :revolution,
           :reyn,
           :rem,
           :rood,
           :rutherford,
           :rydberg,
           :sphere,
           :sthene,
           :stokes,
           :stone,
           :therm,
           :thermie,
           :unified_atomic_mass,
           :sidereal_year,
           :tog,
           :clo ]

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
  Unit.BTU_FiftyNineF.operate do |unit|
    unit.name = 'british thermal unit'
    unit.symbol = 'BTU'
    unit.make_canonical
  end

  # AMEE uses 'day' rather than 'd' as the label for the time period, day
  Unit.day.operate do |unit|
    unit.label = 'day'
    unit.make_canonical
  end

  # Load prefixed version of British thermal unit, which is used in AMEE
  prefix_and_load :M, :BTU_FiftyNineF

  # Define and load the megawatt hour, an energy unit used in AMEE
  construct_and_load(megawatt*hour) do |unit|
    unit.symbol = 'MWh'
    unit.label = 'MWh'
  end
  
end