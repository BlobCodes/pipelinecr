require "./pipelinecr/*"

module PipelineCR
  VERSION = "0.1.0"

  def self.>>(processor : PipelineCR::Processor(T,U)) : PipelineCR::Pipeline(T, U) forall T,U
    input = Channel(T | PipelineCR::PackageAmountChanged).new()
    output = Channel(U | PipelineCR::PackageAmountChanged).new()
    processor.start(input, output)
    PipelineCR::Pipeline(T, U).new(input, output)
  end
end

# Define multiple pipeline stages
require "http/client"
class DownloadStage < PipelineCR::Stage(String, HTTP::Client::Response)
  def initialize()
    # Here you can define important instance-variables, which is not needed in this case
  end

  def task(pkg : String) : HTTP::Client::Response
    HTTP::Client.get(pkg)
  end
end

class SplittingStage < PipelineCR::Stage(HTTP::Client::Response, String)
  # You can even return multiple results per stage, which is automatically split into small pieces
  # Exceptions are also handled to avoid the pipeline becoming malfunctional
  def task(pkg : HTTP::Client::Response) : Array(String)
    raise "Something went wrong" if rand(2) % 2 == 0
    pkg.body.lines.first(3)
  end

  # You can even change the error handling behaviour
  def on_error(ex : Exception)
    puts ex
  end
end

# Create the pipeline
# Multiplying a Stage is required and defines how many fibers should work in parallel
pipeline = PipelineCR >> DownloadStage*4 >> SplittingStage*2

# Create work
packages = [
  "example.com/a_file",
  "example.com/another_file",
]

# Process packages
puts pipeline.flush(packages) # Processes all packages and returns an array with the responses
# (OR)
pipeline.process_each(packages) do |pkg| # Yields each finished package until all packages are finished
  puts pkg
end


# require "http/client"
# class DownloadStage < PipelineCR::Stage(String, String)
#   def initialize()
#     # Here you can define important instance-variables, which is not needed in this case
#   end

#   def task(pkg : String) : String
#     puts "Downloading #{pkg}"
#     HTTP::Client.get(pkg).body
#   end
# end

# class CountStage < PipelineCR::Stage(String, Int32)
#   def initialize()
#     # Here you can define important instance-variables, which is not needed in this case
#   end

#   def task(pkg : String) : Int32
#     pkg.size
#   end
# end

# pipeline = PipelineCR >> DownloadStage*4 >> CountStage*1

# packages = [
#   "https://duckduckgo.com",
#   "https://google.com",
#   "https://amazon.de",
# ]*4

# puts pipeline.flush(packages)
