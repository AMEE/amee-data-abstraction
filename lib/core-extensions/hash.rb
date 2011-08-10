
# Authors::   James Hetherington, James Smith, Andrew Berkeley, George Palmer
# Copyright:: Copyright (c) 2011 AMEE UK Ltd
# License::   Permission is hereby granted, free of charge, to any person obtaining
#             a copy of this software and associated documentation files (the
#             "Software"), to deal in the Software without restriction, including
#             without limitation the rights to use, copy, modify, merge, publish,
#             distribute, sublicense, and/or sell copies of the Software, and to
#             permit persons to whom the Software is furnished to do so, subject
#             to the following conditions:
#
#             The above copyright notice and this permission notice shall be included
#             in all copies or substantial portions of the Software.
#
#             THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#             EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#             MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#             IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#             CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#             TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#             SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# :title: Class: Hash

class Hash

  # Return a new instance of <i>Hash</i> which represents the same data as
  # <tt>self</tt> but with all keys - including those of sub-hashes - symbolized
  #
  def recursive_symbolize_keys
    new_hash = {}
    self.each_pair do |k,v|
      new_hash[k.to_sym] = value_or_symbolize_value(v)
    end
    new_hash
  end

  # Modify <tt>self</tt> in place, transforming all keys - including those of
  # sub-hashes - in to symbols
  #
  def recursive_symbolize_keys!
    self.each_pair do |k,v|
      value = delete(k)
      self[k.to_sym] = value_or_symbolize_value(value)
    end
    self
  end

  private

  # Symbolize any hash key or sub-hash key containing within <tt>value</tt>.
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
