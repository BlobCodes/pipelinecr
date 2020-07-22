abstract class PipelineCR::Stage(T, U) < PipelineCR::Pipeable(T, U)
  def initialize; end

  def run(input : Channel(T), output : Channel(U), host : Channel(Int32))
    spawn do
      loop do
        pkg = input.receive?
        if pkg == nil
          output.close unless output.closed?
          on_close()
          break
        end
        begin
          case sendout = task(pkg.unsafe_as(T))
          when nil
            host.send(-1)
          when .is_a? U
            output.send sendout
          when .is_a? Enumerable(U)
            host.send(sendout.size-1)
            sendout.each { |sendpkg| output.send(sendpkg) }
          end
        rescue ex
          host.send(-1)
          on_error(pkg.not_nil!, ex)
        end
      end
    end
  end

  def self.*(amount : Int32)
    raise "Cannot create zero workers!" if amount == 0
    return self.new if amount == 1
    ret = Array(PipelineCR::Stage(T, U)).new(amount)
    amount.times { ret << self.new }
    PipelineCR::Processor(T, U).new(ret)
  end

  def on_error(pkg : T, ex : Exception)
    puts ex
  end

  def on_close; end

  abstract def task(pkg : T) : U? | Enumerable(U)?
end
