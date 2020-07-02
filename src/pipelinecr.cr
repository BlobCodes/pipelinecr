require "./pipelinecr/*"

module PipelineCR
  VERSION = "0.1.0"

  def self.>>(processor : PipelineCR::Processor(T,U)) : PipelineCR::Pipeline(T, U) forall T,U
    input = Channel(T | PipelineCR::PackageAmountChanged).new()
    output = Channel(U | PipelineCR::PackageAmountChanged).new()
    processor.start(input, output)
    PipelineCR::Pipeline(T, U).new(input, output)
  end
end
