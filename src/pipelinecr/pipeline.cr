class PipelineCR::Pipeline(T, U)
  @input : Channel(T) = Channel(T).new
  @output : Channel(U) = Channel(U).new
  @host : Channel(Int32) = Channel(Int32).new
  @finish : Channel(Nil) = Channel(Nil).new
  @finished : Bool = true
  @receiver : Bool = false

  def initialize(pipeable : Pipeable(T, U))
    pipeable.run(@input, @output, @host)
  end

  def self.build(&block)
    self.new(yield PipelineCR::Builder::Sequence)
  end

  private def host
    raise "You need to setup a package receiver first!" unless @receiver
    @finished = false
    spawn do
      counter = 0
      loop do
        counter += @host.receive
        break if counter <= 0
      end
      @finished = true
      @finish.send(nil)
    end
  end

  def <<(package : T)
    host if @finished
    @host.send(1)
    @input.send(package)
  end

  def <<(packages : Enumerable(T))
    host if @finished
    @host.send(packages.size)
    packages.each { |pkg| @input.send(pkg) }
  end

  def close
    @input.close
    @output.close
    @host.close
  end

  def on_receive(&block : U -> Nil)
    raise "There can't be multiple receivers" if @receiver
    @receiver = true
    spawn do
      until nil == (pkg = @output.receive?)
        block.call(pkg.not_nil!)
        @host.send(-1)
      end
    end
  end

  def receiver=(array : Array(U))
    on_receive do |pkg|
      array << pkg
    end
  end

  def finish
    @finish.receive
  end
end
