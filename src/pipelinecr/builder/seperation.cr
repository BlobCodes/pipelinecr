struct PipelineCR::Builder::Seperation(T, U)
  @values = [] of Tuple(PipelineCR::Pipeable(T, U), Proc(T, Bool))
  @fallback : PipelineCR::Pipeable(T, U)? = nil

  def initialize()
  end

  def |(args : Tuple(PipelineCR::Pipeable(T, U), Proc(T, Bool)))
    @values << args
    self
  end

  def >>(pipeable : PipelineCR::Pipeable(T, U))
    @fallback = pipeable
    self
  end

  def value
    PipelineCR::Seperation.new(@values, @fallback)
  end

  def self.|(args : Tuple(PipelineCR::Pipeable(T, U), Proc(T, Bool))) forall T,U
    PipelineCR::Builder::Seperation(T, U).new | args
  end
end
