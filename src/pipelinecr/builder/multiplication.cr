struct PipelineCR::Builder::Multiplication(T, U)
  @values = [] of PipelineCR::Pipeable(T, U)

  def initialize
  end

  def >>(pipeable : PipelineCR::Pipeable(T, U))
    @values << pipeable
    self
  end

  def &(pipeable : PipelineCR::Pipeable(T, V)) forall V
    @values << (pipeable >> PipelineCR::Void(V, U).new)
    self
  end

  def value
    PipelineCR::Multiplication.new(@values)
  end

  def self.>>(pipeable : PipelineCR::Pipeable(T, U)) forall T, U
    PipelineCR::Builder::Multiplication(T, U).new >> pipeable
  end

  def self.&(other)
    {% raise "You need to add a regular pipeable using the >>=(other) method first!" %}
  end
end
