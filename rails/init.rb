require 'amee-data-abstraction.rb'

module AMEE::DataAbstraction
  # Override the connection accessor to provide the global connection in rails apps
  def self.connection
    AMEE::Rails.connection
  end
end
