#Note to self, do this only for ruby 1.8.x
class Proc
  def===(x)
    call(x)
  end
end