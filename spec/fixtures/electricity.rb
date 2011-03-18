Electricity=AMEE::DataAbstraction::PrototypeCalculation.new { # The application has support for an electricity calculation. :electricity is the internal label used to refer to it
  label :electricity
  name "Electricity Consumption"
  path '/business/energy/electricity/grid'
  
  drill {
    value 'argentina' #Not to be unset, value pre-given
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
    type :text_box #Probably not needed, as likely to be the default for profile item value unsets
    validation :float #Probably not needed, as default can be deduced from PIV TYPE in API. Here as illustrative of potential override Can be a symbol for standard validation or regexp
    other_acceptable_units :any #A dropdown should appear allowing choice of energy unit - without this line only kWh allowed
  }
  
  # Alternatively, the drill might be fixed
  #permanent :country {
  #   drill_path 'country'
  #   value 'Argentina'

  output { #A marv output value
    label :co2
    path :default #It's not a marv, use the default output
    name "Carbon Dioxide"
  }
}

