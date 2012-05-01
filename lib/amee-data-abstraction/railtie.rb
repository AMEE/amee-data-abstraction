require 'amee-data-abstraction'
require 'rails'

module AMEE::DataAbstraction

  class Railtie < Rails::Railtie

    rake_tasks do
      load File.join(File.dirname(__FILE__), '..', "tasks", "amee_data_abstraction.rake")
    end
  end

end