# A module to indicate that something can be used as a part of a pipeline
abstract class PipelineCR::Pipeable(T, U)
  abstract def run(input : Channel(T), output : Channel(U), host : Channel(Int32))

  def >>(other : PipelineCR::Pipeable(U, V)) forall V
    PipelineCR::Bridge(T, U, V).new(self, other)
  end
end
