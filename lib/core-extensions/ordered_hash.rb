module ActiveSupport
  class OrderedHash
    def stable_select(&block)
      #Annoyingly, default ordered hash select is not stable
      self.map{|k,v| block.call(k,v) ? [k,v] : nil}.compact
    end
  end
end
