class PipelineCR::Processor(T, U)
  @stages : Array(Stage(T, U))

  def initialize(@stages : Array(Stage(T, U)))
  end

  def start(input : Channel(T | PipelineCR::PackageAmountChanged), output : Channel(U | PipelineCR::PackageAmountChanged))
    @stages.each {|stage| stage.start(input, output)}
  end
end
