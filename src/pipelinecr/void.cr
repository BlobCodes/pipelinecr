# End of a sequence, destroying each received package
class PipelineCR::Void(T, U) < PipelineCR::Pipeable(T, U)
  def initialize
  end

  def run(input : Channel(T), output : Channel(U), host : Channel(Int32))
    spawn do
      until input.receive? == nil
        host.send(-1)
      end
    end
  end
end
