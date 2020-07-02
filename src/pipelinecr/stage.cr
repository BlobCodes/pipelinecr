abstract class PipelineCR::Stage(T, U)
  def initialize; end

  def start(input : Channel(T | PipelineCR::PackageAmountChanged), output : Channel(U | PipelineCR::PackageAmountChanged))
    spawn do
      loop do
        begin
          pkg = input.receive
          if pkg.is_a?(PipelineCR::PackageAmountChanged)
            output.send pkg
            next
          end
          begin
            case sendout = task(pkg.unsafe_as(T))
            when .is_a? U
              output.send sendout
            when .is_a? Enumerable(U)
              output.send PipelineCR::PackageAmountChanged.new(sendout.size-1)
              sendout.each {|sendpkg| output.send(sendpkg)}
            end
          rescue ex
            on_error(ex)
            output.send PipelineCR::PackageAmountChanged.new(-1)
          end
        rescue Channel::ClosedError
          output.close unless output.closed?
          break
        end
      end
    end
  end

  def self.*(amount : Number)
    ret = Array(PipelineCR::Stage(T, U)).new(amount)
    amount.times { ret << self.new() }
    PipelineCR::Processor(T, U).new(ret)
  end

  def on_error(ex : Exception)
    puts ex
  end

  abstract def task(pkg : T) : U | Enumerable(U)
end


