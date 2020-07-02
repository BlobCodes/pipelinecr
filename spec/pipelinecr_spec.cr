require "./spec_helper"

class CleaningStage < PipelineCR::Stage(Int32, Int32)
  def task(pkg : Int32) : Int32
    raise "Nope" if pkg > 40
    pkg
  end
end

class SquareStage < PipelineCR::Stage(Int32, Int32)
  def task(pkg : Int32) : Int32
    pkg * pkg
  end
end

class IntParsingStage < PipelineCR::Stage(String, Int32)
  def task(pkg : String) : Int32
    pkg.to_i32
  end

  def on_error(pkg : String, ex : Exception)
    puts "#{pkg} is not an Int!"
  end
end

class StringSplittingStage < PipelineCR::Stage(String, String)
  def task(pkg : String) : Array(String)
    pkg.split(" ")
  end
end

describe PipelineCR do
  it "passes the pipeline" do
    pipeline = PipelineCR >> StringSplittingStage*1 >> IntParsingStage*4 >> SquareStage.new >> CleaningStage*2
    pipeline.flush(["4 2 3 7", "2 3"]).sort.should eq([4, 4, 9, 9, 16])
    pipeline.flush(["4 2 3 7", "2 3"]).sort.should eq([4, 4, 9, 9, 16])
  end
end
