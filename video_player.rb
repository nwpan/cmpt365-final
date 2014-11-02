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
    @viewport = Viewport.new(320, 200)
    @video_playback = VideoPlayback.new(@video_1)
  end

  def paintEvent event
    painter = Qt::Painter.new
    painter.begin self
    drawFrames painter
    painter.end
  end

  def drawFrames painter
    painter.setPen Qt::NoPen

    @viewport.frame = @video_playback.getFrame(@time.elapsed)
    image = Qt::Image.new(@viewport.frame.data, @viewport.width, @viewport.height, Qt::Image.Format_RGB888)
    painter.drawImage 0, 0, image
  end

end

class Viewport
  attr_reader :frame, :width, :height

  def initialize(width, height)
    self.width = width
    self.height = height
  end

  attr_writer :frame, :width, :height
end

class VideoPlayback
  attr_reader :main_video, :videos

  def initialize(main_video)
    self.main_video = main_video
  end

  def getFrame(time_elapsed)
    return nil if main_video.nil? || main_video.frames_count <= 0
    frame_number = (time_elapsed / $FRAMES_PER_SECOND) % main_video.frames_count
    puts "Frame #: #{frame_number}" if $DEBUG == true
    main_video.frames[frame_number]
  end

  def videoWipe(start, video_id)

  end

private
  attr_writer :main_video, :videos
end

class Video
  attr_reader :frames, :frames_count

  def initialize(file)
    self.frames = getFrames(file)
    self.frames_count = frames.size
  end


  attr_writer :frames, :frames_count
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

