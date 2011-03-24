ElectricityAndTransport=AMEE::DataAbstraction::CalculationSet.new {
  all_calculations {
    metadatum {
      label :department
      choices %w{stuff things more_stuff meta_things}
    }
  }

  calculation{
    name 'electricity'
    label :electricity
    path '/business/energy/electricity/grid'
    profile {
      label :usage
      name 'Electricity Used'
      path 'energyPerTime'
    }
    drill {
      label :country
      path 'country'
      fixed 'Argentina'
    }
    output {
      label :co2
      path :default
    }
  }

  calculation {
    name 'transport'
    label :transport
    path '/transport/car/generic'

    drill {
      path 'fuel'
      label :fuel
      name 'Fuel Type'
    }
    drill {
      path 'size'
      label :size
      name 'Vehicle Size'
    }
    profile {
      path 'distance'
      label :distance
      name 'Distance Driven'
    }
    output {
      label :co2
      path :default
      name 'Carbon Dioxide'
    }
  }
}