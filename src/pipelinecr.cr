require "./pipelinecr/*"

module PipelineCR
  VERSION = "0.2.0"

  def self.>>(pipeable : PipelineCR::Pipeable(T, U)) : PipelineCR::Pipeline(T, U) forall T, U
    input = Channel(T | PipelineCR::PackageAmountChanged).new
    output = Channel(U | PipelineCR::PackageAmountChanged).new
    pipeable.start(input, output)
    PipelineCR::Pipeline(T, U).new(input, output)
  end
end
