# A wrapper around multiple pipeables where each package sent to the first pipeable that accepts it
class PipelineCR::Seperation(T, U) < PipelineCR::Pipeable(T, U)
  @pipeables : Array(Tuple(Pipeable(T, U), Proc(T, Bool)))
  @fallback : Pipeable(T, U)?

  def initialize(@pipeables : Array(Tuple(Pipeable(T, U), Proc(T, Bool))), @fallback : Pipeable(T, U)? = nil)
  end

  def run(input : Channel(T), output : Channel(U), host : Channel(Int32))
    processed = @pipeables.map do |pipeable|
      input_channel = Channel(T).new
      pipeable[0].run(input_channel, output, host)
      {pipeable[1], input_channel}
    end
    fallback : Tuple(Nil, Channel(T))? = nil
    if @fallback
      fallback_channel = Channel(T).new
      @fallback.not_nil!.run(fallback_channel, output, host)
      fallback = {nil, fallback_channel}
    end
    spawn do
      while pkg = input.receive
        chosen = processed.find(fallback) { |entry| entry[0].call(pkg) }
        chosen ? chosen.not_nil![1].send(pkg) : host.send(-1)
      end
    end
  end
end
