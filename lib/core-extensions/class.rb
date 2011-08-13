# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

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
