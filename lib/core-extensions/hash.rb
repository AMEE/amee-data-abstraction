
class Hash

  def recursive_symbolize_keys
    new_hash = {}
    self.each_pair do |k,v|
      new_hash[k.to_sym] = value_or_symbolize_value(v)
    end
    new_hash
  end

  def recursive_symbolize_keys!
    self.each_pair do |k,v|
      value = delete(k)
      self[k.to_sym] = value_or_symbolize_value(value)
    end
    self
  end

  private

  def value_or_symbolize_value(value)
    if value.is_a? Hash
      return value.recursive_symbolize_keys
    elsif value.is_a? Array
      return value.map { |elem| value_or_symbolize_value(elem) }
    else
      return value
    end
  end

end
