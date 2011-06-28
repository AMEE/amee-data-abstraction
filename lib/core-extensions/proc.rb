
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