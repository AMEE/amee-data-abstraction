
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
# :title: Class: Class

class Class

  # Syntactic sugar for providing instance level attributes. Similar to
  # <tt>attr_accessor</tt> except the value of property is set without requiring
  # "=" syntax, e.g.
  # 
  #   foo.propname 5        (rather than <tt>foo.attrname=5</tt>)
  #
  #   foo.propname            #=> 5
  #
  # In other words, setting is performed by specifing an argument, getting is
  # performed using the same method call without an argument.
  #
  def attr_property(*accessors)
    accessors.each do |m|
      define_method(m) do |*val|
        instance_variable_set("@#{m}",val.first) unless val.empty? #Array Hack to avoid warning
        instance_variable_get("@#{m}")
      end
    end
  end
end
