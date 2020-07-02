# PipelineCR

Pipelines are a simple way to efficiently parallelize workloads consisting of multiple asynchronous subtasks.

## Installation

1. Add the dependency to your `shard.yml`:
   
   ```yaml
   dependencies:
     pipelinecr:
       github: blobcodes/pipelinecr
   ```

2. Run `shards install`

## Usage

```crystal
require "pipelinecr"

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
  def on_error(pkg : HTTP::Client::Response, ex : Exception)
    puts ex
  end

  # You can clean up after you're finished with processing
  def on_close()
    puts "Stopped a SplittingStage worker."
  end
end

# Create the pipeline
# Multiplying a Stage defines how many fibers should work in parallel, but you can also initialize a Stage directly
pipeline = PipelineCR >> DownloadStage*4 >> SplittingStage.new

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
```

Please keep in mind that the pipeline can only process one set of packages at a time. You cannot use multiple fibers to process multiple fibers

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/blobcodes/pipelinecr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [BlobCodes](https://github.com/blobcodes) - creator and maintainer
