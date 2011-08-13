# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Class: OrderedHash

module ActiveSupport
  class OrderedHash

    # Version of enumerable#select for an OrderedHash which is order-preserving
    # Output is an array of key-value pairs.
    def stable_select(&block)
      #Annoyingly, default ordered hash select is not stable
      self.map{|k,v| block.call(k,v) ? [k,v] : nil}.compact
    end

    # Insert a given element at the beginning, not end, of an ordered hash.
    def insert_at_start(key,value)
      replace(OrderedHash[self.to_a.insert(0,[key,value])])
      end
  end
end
