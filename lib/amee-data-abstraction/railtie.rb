#require 'amee-data-abstraction'
require 'rails'

module AMEE::DataAbstraction

  class Railtie < Rails::Railtie
    railtie_name :amee_data_abstraction

    rake_tasks do
      load "tasks/amee_data_abstraction.rake"
    end
  end

end