#Note to self, do this only for ruby 1.8.x
class Proc

  # For ruby 1.8, define === operator for a proc
  def===(x)
    call(x)
  end
end