Transport=AMEE::DataAbstraction::PrototypeCalculation.new{
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
    path 'default'
    name 'Carbon Dioxide'
  }
}