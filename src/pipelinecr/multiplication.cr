# A wrapper around multiple pipeables where each package sent to it is forwarded to each pipeable
class PipelineCR::Multiplication(T, U) < PipelineCR::Pipeable(T, U)
  @pipeables : Array(Pipeable(T, U))
  @addition : Int32

  def initialize(@pipeables : Array(Pipeable(T, U)))
    @addition = @pipeables.size-1
  end

  def run(input : Channel(T), output : Channel(U), host : Channel(Int32))
    input_channels = [] of Channel(T)
    @pipeables.each do |pipeable|
      input_channels << (input_channel = Channel(T).new)
      pipeable.run(input_channel, output, host)
    end
    spawn do
      until nil == (pkg = input.receive?)
        host.send(@addition)
        input_channels.each &.send(pkg.not_nil!)
      end
    end
  end
end
