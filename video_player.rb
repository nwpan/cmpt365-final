class VideoPlayer < Qt::Widget
  def initialize(parent)
    super(parent)

    @timer = Qt::Timer.new(self)
    connect(@timer, SIGNAL('timeout()'), self, SLOT('update()'))
    @timer.start($FRAMES_PER_SECOND)
    setFocusPolicy Qt::StrongFocus

    initVideo
  end

  def initVideo
    @frames = getFrames("./assets/earth.avi")
    @frame_count = @frames.size
    @time = Qt::Time.currentTime
  end

  def paintEvent event
    painter = Qt::Painter.new
    painter.begin self
    drawFrames painter
    painter.end
  end

  def drawFrames painter
    painter.setPen Qt::NoPen

    frame_number = (@time.elapsed / $FRAMES_PER_SECOND) % @frame_count

    puts "Frame #: #{frame_number}"
    frame = @frames[frame_number]
    image = Qt::Image.new(frame.data, frame.width, frame.height, Qt::Image.Format_RGB888)
    painter.drawImage 0, 0, image
  end

private
  def getFrames(file)
    frames = Array.new
    File.open(file) do |io|
      FFMPEG::Reader.open(io) do |reader|
        video_stream = reader.streams.select { |s| s.type == :video }.first
        raise "File does not contain a video stream" unless video_stream
        while frame = video_stream.decode ^ video_stream.resampler(:rgb24) do
          break unless frame.instance_of?(FFMPEG::VideoFrame)
          frames << frame
        end
      end
    end
    return frames
  end
end