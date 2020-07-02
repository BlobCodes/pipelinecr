# Pipelines are a simple way to efficiently parallelize workloads consisting of multiple asynchronous subtasks.
#
# Example:
# DownloadStage, ConversionStage and FinalizationStage are the three subtasks that need to run.
# ```
# pipeline = |> DownloadStage*4 => ConversionStage*2 => FinalizationStage*1
#
# finished = Array(String).new
# pipeline.each_finished { |pkg| finished << pkg }
#
# pipeline.process(stuff)
# pipeline.process(more_stuff)
# [...]
#
# pipeline.finish
# puts finished
# ```
#
# Example of a Stage:
# ```
# class DownloadStage < Pipeline::Stage(URI, String)
#   def initialize()
#     # Here you can define important instance-variables
#   end
#
#   def task(pkg : URI) : String
#     HTTP::Client.get(pkg).body
#   end
# end
# ```
class PipelineCR::Pipeline(T, U)
  VERSION = "0.1.0"

  @input : Channel(T | PipelineCR::PackageAmountChanged)
  @output : Channel(U | PipelineCR::PackageAmountChanged)
  # @finished = Channel(Nil).new

  def initialize(@input : Channel(T | PipelineCR::PackageAmountChanged), @output : Channel(U | PipelineCR::PackageAmountChanged))
  end

  def >>(pro : Processor(U, V)) : PipelineCR::Pipeline forall V
    output = Channel(V | PipelineCR::PackageAmountChanged).new()
    pro.start(@output, output)
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
    packages.each {|pkg| @input.send(pkg)}
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

  def finished?
    @finished.closed?
  end

  def abort
    @input.close
    @finished.close
  end
end
