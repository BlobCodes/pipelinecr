# A task in the pipeline
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
#
#   # You can even change the error handling behaviour
#   def on_error(pkg : String, ex : Exception)
#     puts ex
#   end
#
#   # You can clean up after you're finished with processing
#   def on_close()
#     puts "Stopped a DownloadStage worker."
#   end
# end
# ```
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
            on_error(pkg.unsafe_as(T), ex)
            output.send PipelineCR::PackageAmountChanged.new(-1)
          end
        rescue Channel::ClosedError
          output.close unless output.closed?
          on_close()
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

  def on_error(pkg : T, ex : Exception)
    puts ex
  end

  def on_close(); end

  abstract def task(pkg : T) : U | Enumerable(U)
end


