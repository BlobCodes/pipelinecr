# A bridge between two pipeables having different in- and outputs. Used for building sequences.
class PipelineCR::Bridge(T, U, V) < PipelineCR::Pipeable(T, V)

  def initialize(@input : PipelineCR::Pipeable(T, U), @output : PipelineCR::Pipeable(U, V))
  end

  def run(input : Channel(T), output : Channel(V), host : Channel(Int32))
    bridge_channel = Channel(U).new
    @input.run(input, bridge_channel, host)
    @output.run(bridge_channel, output, host)
  end
end
