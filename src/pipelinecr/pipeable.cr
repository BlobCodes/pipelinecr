# A module to indicate that something can be used as a part of a pipeline
abstract class PipelineCR::Pipeable(T, U)
  abstract def start(input : Channel(T | PipelineCR::PackageAmountChanged), output : Channel(U | PipelineCR::PackageAmountChanged))
end
