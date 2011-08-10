== amee-data-abstraction

The amee-data-abstraction gem provides an easy-to-use, highly configurable interface
for providing AMEE-driven calculations to Rails applications.

Licensed under the BSD 3-Clause license (See LICENSE.txt for details)

Authors: James Hetherington, James Smith, Andrew Berkeley, George Palmer

Copyright: Copyright (c) 2011 AMEE UK Ltd

Homepage: http://github.com/AMEE/amee-data-abstraction

Documentation: http://rubydoc.info/gems/amee-data-abstraction

== INSTALLATION

 gem install amee-data-abstraction

== REQUIREMENTS

 * ruby 1.8.7
 * rubygems >= 1.5

 All gem requirements should be installed as part of the rubygems installation process 
 above, but are listed here for completeness.

 * amee ~> 3.0
 * uuidtools = 2.1.2
 * quantify = 1.1.0
 
== USAGE

The library provides several useful functions:

1. Abstracts away most of the details for making API calls into an elegant DSL-style
configuration.

2. Provides a host of macro-style helper methods for rapidly generating
calcualtion templates

3. Models each type of AMEE calculation as a fully configurable Ruby object.

4. Enables the configuring of which inputs (drills and profile item values) and
outputs (return values) to handle and display for each calculation type.

5. Enables configuration of default interfaces (select lists, text fields, etc.)
for calculation components.

6. Enables customised, human-readable names and other descriptors to be associated
with calculations or calculation components (inputs, outputs, etc.).

7. Enables arbitrary metadata to be associated with calculations.

8. Provides support for handling alternative units, including full configurability.


=== Brief introduction

The calculations provided by AMEE categories are represented by instances of the
class AMEE::DataAbstraction::Calculation.

This class has two subclasses, (1) PrototypeCalculation, which is used to
represent a blank calculation template for a particular type of calculation; and
(2) OngoingCalculation, instances of which represent actual individual calculations
which are made.

Calculation objects contain instances of the AMEE::DataAbstraction::Term class.
The Term class, and its subclasses Input, Drill, Profile, Metadatum, Usage, and
Output, represent components of a calculation such as inputs, outputs (i.e.
caluclated values) and arbitrary metadatum.

Prototype calculations can be contained within an instance of the class
AMEE::DataAbstraction::CalculationSet, in order to provide rapid access to any
defined calculation templates and instantiating of a new instance of a real
calcualtion.

=== Example usage

Configure a calculation

  include AMEE::DataAbstraction

  my_template_calculation = PrototypeCalculation.new {

    label :electricity                         # Custom unique label
    name "Grid electricity supply"             # Custom name
    path "/some/path/in/the/amee/platform"     # AMEE platform category path
    terms_from_amee                            # helper for initializing and
                                                 configuring all calculation
                                                 terms based on AMEE platform
  }

                          #=> <AMEE::DataAbstraction::PrototypeCalculation ... >

Create a new calculation instance

  my_calculation = my_template_calculation.begin_calculation

                          #=> <AMEE::DataAbstraction::OngoingCalculation ... >

Set the calculation inputs

  params = { :country => 'Sweden',
             :consumption => { :value => 6000, :unit => 'kWh' }}

  my_calculation.choose! params

Submit to AMEE for calculation

  my_calculation.calculate!

  my_calculation[:co2].to_s     #=> "2456 kg"


=== Configuring mutliple application calculation prototypes

Typical practice is initialize the calculation prototypes required for an
application via a configuration file which creates the required calculation
templates within an instance of CalculationSet. If the calculation set is assigned
to a global variable or constant, the set of prototypes is available for
initializing new calculations and templating view structures (e.g. tables, forms)
from anywhere in the application.

Adding a configuration to /config or /config/initializers may be appropriate

  # e.g. /config/initializers/calculations.rb

   Calculations = AMEE::DataAbstraction::CalculationSet {

    calculation {
      label :electricity
      name "Grid Electricity Supply"
      path "/some/electricity/associated/path/in/amee"
      terms_from_amee
    }

    calculation {
      label :transport
      name "Employee Commuting"
      path "/some/transport/associated/path/in/amee"
      terms_from_amee
    }

    calculation {
      label :fuel
      name "Fuel Consumption"
      path "/some/fuel/associated/path/in/amee"
      terms_from_amee
    }
  }

                          #=> <AMEE::DataAbstraction::CalculationSet ... >

From this global calculation set, initialize a new calculation

  my_fuel_calculation = Calculations[:fuel].begin_calculation

                          #=> <AMEE::DataAbstraction::OngoingCalculation ... >

  a_different_transport_calculation = Calculations[:transport].begin_calculation

                          #=> <AMEE::DataAbstraction::OngoingCalculation ... >

=== Configuring a connection to AMEE

The AMEE::DataAbstraction module uses the 'amee' ruby gem to interact with AMEE.
The standard method for configuring and instantiating a connection to the AMEE
API is to provide authentication credentials in the /config/amee.yml file,
structured thus:

  ---
  production:
    server: live.amee.com
    username: <some user name>
    password: <some password>
    cache: rails

  development:
    server: stage.amee.com
    username: <some user name>
    password: <some password>
    cache: rails

  test:
    server: stage.amee.com
    username: <some user name>
    password: <some password>
