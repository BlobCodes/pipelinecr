require "./pipelinecr/pipeable"
require "./pipelinecr/**"

module PipelineCR
  VERSION = "0.3.1"

  def self.multiply(&block)
    (yield PipelineCR::Builder::Multiplication).value
  end

  def self.sequence(&block)
    yield PipelineCR::Builder::Sequence
  end

  def self.seperate(&block)
    (yield PipelineCR::Builder::Seperation).value
  end
end
