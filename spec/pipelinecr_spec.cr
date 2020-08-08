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

class DoubleStage < PipelineCR::Stage(Int32, Int32)
  def task(pkg : Int32) : Int32
    pkg * 2
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

class CountingStage < PipelineCR::Stage(Int32, Nil)
  @@count = 0

  def task(pkg : Int32) : Nil
    @@count += pkg
  end

  def self.count
    @@count
  end
end

describe PipelineCR do
  it "finishes a complex pipeline correctly" do
    pipeline = PipelineCR::Pipeline(String, Int32).build do |pipe|
      pipe >>= StringSplittingStage*1
      pipe >>= IntParsingStage*4
      pipe >>= PipelineCR.multiply do |pipe|
        pipe >>= SquareStage.new
        pipe >>= DoubleStage*2
        pipe >>= PipelineCR.sequence do |pipe|
          pipe >>= SquareStage*4
          pipe >>= DoubleStage.new
        end
        pipe &= CountingStage.new
        pipe >>= PipelineCR.seperate do |pipe|
          pipe |= {SquareStage*1, ->(pkg : Int32) { pkg == 4 }}
        end
      end
      pipe >>= CleaningStage*2
    end

    pipeline.receiver = (receiver = Array(Int32).new)
    pipeline << ["4 2 3 7 e"]
    pipeline << "2 3"
    pipeline.finish
    receiver.sort.should eq([4, 4, 4, 4, 6, 6, 8, 8, 8, 9, 9, 14, 16, 16, 18, 18, 32])

    pipeline << ["4 2 3 7", "2 3"]
    pipeline.finish
    receiver.sort.should eq([4, 4, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 14, 14, 16, 16, 16, 16, 18, 18, 18, 18, 32, 32])

    pipeline.close

    CountingStage.count.should eq(42)
  end
end
