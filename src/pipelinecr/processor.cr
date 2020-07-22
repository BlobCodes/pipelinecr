# A wrapper around multiple stages processing the same thing to enable easy parallelism, created by multiplying a Stage with a number
class PipelineCR::Processor(T, U) < PipelineCR::Pipeable(T, U)
  @stages : Array(Stage(T, U))

  def initialize(@stages : Array(Stage(T, U)))
  end

  def run(input : Channel(T), output : Channel(U), host : Channel(Int32))
    @stages.each { |stage| stage.run(input, output, host) }
  end
end
