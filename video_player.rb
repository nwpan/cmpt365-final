class VideoPlayer < Qt::Widget
  def initialize(parent)
    super(parent)

    @timer = Qt::Timer.new(self)
    connect(@timer, SIGNAL('timeout()'), self, SLOT('update()'))
    setFocusPolicy Qt::StrongFocus

    initVideo
    @timer.start($FRAMES_PER_SECOND)
  end

  def initVideo
    @video_1 = Video.new("./assets/earth.avi")
    @video_2 = Video.new("./assets/bailey.mpg")
    @time = Qt::Time.currentTime
    @height_cnt = 0
  end

  def paintEvent event
    painter = Qt::Painter.new
    painter.begin self
    drawFrames painter
    painter.end
  end

  def drawFrames painter
    painter.setPen Qt::NoPen

    return if @video_1.frames.nil?

    frame_number = (@time.elapsed / $FRAMES_PER_SECOND) % @video_1.frames_count

    puts "Frame #: #{frame_number}"
    frame = @video_1.frames[frame_number]
    image = Qt::Image.new(frame.data, frame.width, frame.height, Qt::Image.Format_RGB888)
    painter.drawImage 0, 0, image

    frame = @video_2.frames[frame_number]
    image = Qt::Image.new(frame.data, frame.width, @height_cnt, Qt::Image.Format_RGB888)
    painter.drawImage 0, 0, image

    @height_cnt += 1
  end

end

class Video
  attr_reader :frames, :frames_count, :width, :height

  def initialize(file)
    self.frames = getFrames(file)
    self.frames_count = frames.size
    self.width = frames.first.width
    self.height = frames.first.height
  end

private
  attr_writer :frames, :frames_count, :width, :height

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