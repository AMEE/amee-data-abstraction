# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

class Proc

  # Shorthand method for calling <tt>self</tt> passing <tt>x</tt> as a block 
  # variable.
  # 
  # This is required for ruby 1.8 only, as it mimics functionality added in
  # version 1.9
  #
  def===(x)
    call(x)
  end
end