module PipelineCR::Builder::Sequence
  def self.>>(other : PipelineCR::Pipeable(T, V)) forall T,V
    other
  end
end
