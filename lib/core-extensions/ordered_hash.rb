module ActiveSupport
  class OrderedHash
    def stable_select(&block)
      #Annoyingly, default ordered hash select is not stable
      self.map{|k,v| block.call(k,v) ? [k,v] : nil}.compact
    end
    def insert_at_start(key,value)
      replace(OrderedHash[self.to_a.insert(0,[key,value])])
      end
  end
end
