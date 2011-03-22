module AMEE
  module DataAbstraction
    module Exceptions
      class DSL < Exception; end
      class InvalidInterface < Exception ; end
      #class PrototypeInterference < Exception; end
      class FixedValueInterference < Exception; end
      #class EntryOrderException < Exception; end
    end
  end
end
