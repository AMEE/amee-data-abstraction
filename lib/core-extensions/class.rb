class Class
  def attr_property(*accessors)
    accessors.each do |m|
      define_method(m) do |*val|
        instance_variable_set("@#{m}",val.first) unless val.empty? #Array Hack to avoid warning
        instance_variable_get("@#{m}")
      end
    end
  end
end
