ElectricityAndTransport=AMEE::DataAbstraction::CalculationSet.new {
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
      value 'Argentina'
    }
    output {
      label :co2
      path :default
    }
  }
}
