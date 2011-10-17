Electricity=AMEE::DataAbstraction::PrototypeCalculation.new { # The application has support for an electricity calculation. :electricity is the internal label used to refer to it
  label :electricity
  name "Electricity Consumption"
  path '/business/energy/electricity/grid'
  
  drill {
    fixed 'argentina' #Not to be unset, value pre-given
    label :country  #Name will default to label.humanize if not given
    path 'country' #Some of the fields on the form are drill-downs, but the application doesn't need to display these differently
    #type :autocompleting_text_box #default for a drill with entries is probably a dropdown
  }

  profile {
    label :energy_used
    # Symbol provided here is used in generating html ids for elements etc
    path 'energyPerTime' #The amee profile item value corresponding to the field
    name "Energy Used" #The display name used on the form
    unit "kWh" #Default unit choice
    interface :text_box #Probably not needed, as likely to be the default for profile item value unsets
    validation lambda{|x|x.is_a? Float} #Probably not needed, as default can be deduced from PIV TYPE in API. Here as illustrative.
    alternative_units :MWh, :MBTU, :BTU # If these are explcitly specified then the alternatives are limited to only these units. Otherwise all dimensionally equivalent units are available as alternatives by default
  }
  
  # Alternatively, the drill might be fixed
  #permanent :country {
  #   drill_path 'country'
  #   value 'Argentina'

  output { #A marv output value
    label :co2
    path 'default' #It's not a marv, use the default output
    name "Carbon Dioxide"
  }
}

