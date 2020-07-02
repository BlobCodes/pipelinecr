# Pipelines are a simple way to efficiently parallelize workloads consisting of multiple asynchronous subtasks.
#
# Example:
# ```
# pipeline = PipelineCR >> MultiplyByTwoStage*4 >> MultiplyByTwoStage*1
# packages = [9, 4, 6, 2]
# finished = pipeline.flush(packages) => [36, 16, 24, 8] (Maybe in different order)
# pipeline.process_each(packages) {|pkg| puts pkg} => 3616248 (Maybe in different order)
# ```
class PipelineCR::Pipeline(T, U)
  VERSION = "0.1.0"

  @input : Channel(T | PipelineCR::PackageAmountChanged)
  @output : Channel(U | PipelineCR::PackageAmountChanged)

  def initialize(@input : Channel(T | PipelineCR::PackageAmountChanged), @output : Channel(U | PipelineCR::PackageAmountChanged))
  end

  def >>(pipeable : Pipeable(U, V)) : PipelineCR::Pipeline forall V
    output = Channel(V | PipelineCR::PackageAmountChanged).new
    pipeable.start(@output, output)
    PipelineCR::Pipeline(T, V).new(@input, output)
  end

  def process_each(packages : Enumerable(T), &block : U -> Nil)
    return_channel = Channel(Nil).new
    in_pipeline = packages.size
    spawn do
      until in_pipeline == 0
        pkg = @output.receive
        if pkg.is_a?(PipelineCR::PackageAmountChanged)
          in_pipeline += pkg.value
        else
          block.call(pkg.unsafe_as(U))
          in_pipeline -= 1
        end
      end
      return_channel.send(nil)
    end
    packages.each { |pkg| @input.send(pkg) }
    return_channel.receive
    return_channel.close
  end

  def flush(packages : Enumerable(T)) : Array(U)
    ret = Array(U).new(packages.size)
    process_each(packages) do |pkg|
      ret << pkg
    end
    ret
  end

  def abort
    @input.close
  end
end
