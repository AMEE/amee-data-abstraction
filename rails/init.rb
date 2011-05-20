require 'amee-data-abstraction.rb'

module AMEE
  module DataAbstraction
    # Override the connection accessor to provide the global connection in rails apps
    def connection
      AMEE::Rails.connection
    end
  end
end