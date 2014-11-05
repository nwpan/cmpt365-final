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
    video_1 = Video.new("./assets/MELT.MPG")
    video_2 = Video.new("./assets/DELTA.MPG")
    @time = Qt::Time.currentTime
    #@viewport = Viewport.new(64, 64)
    @viewport = Viewport.new(320, 200)
    @video_playback = VideoPlayback.new(video_1, 320, 200)
    @video_playback.videos << video_2
    @video_playback.videoWipe(0, 0)
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
    image = Qt::Image.new(@viewport.frame, @viewport.width, @viewport.height, Qt::Image.Format_RGB888)
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
  attr_reader :main_video, :videos, :width, :height

  def initialize(main_video, width, height)
    self.width = width
    self.height = height
    self.main_video = main_video
    self.videos = Array.new
    @count = 0
  end

  def getFrame(time_elapsed)
    return nil if main_video.nil? || main_video.frames_count <= 0
    frame_number = (time_elapsed / $FRAMES_PER_SECOND) % main_video.frames_count
    puts "Frame #: #{frame_number}" if $DEBUG == true
    main_video.frames[frame_number]
  end

  def videoWipe(start, video_id)
    next_video = videos[video_id]


    # This is a confusing part, calculates the steps required for one transition.
    # Basically each element in the array is represented by 3 values of 255, (R, G, B).
    # So if we have a 64-by-64 frame, we have 3 colours * 64 height pixels * 64 width
    # pixels, which equals 12288. main_video.frames[0].size/3/320
    transition_time = 98
    width_actual = self.width*3
    end_pos = height*width_actual

    cnt = width-1
    for c in 0..transition_time
      main_data = main_video.frames[c].unpack('C*')
      next_data = next_video.frames[c].unpack('C*')
      #raise "ERROR: Dimension problems." unless main_video.frames.size != transition_time * 3 * 64

      for row in 0..height
        row_actual = row*width_actual
        for col in (width-1).downto(cnt)
          col_actual = col*3
          pos_actual = (col_actual-row_actual)

          if next_data[pos_actual].nil?
            break
          end
          red = next_data[pos_actual]
          green = next_data[pos_actual+1]
          blue = next_data[pos_actual+2]

          main_data[pos_actual] = red
          main_data[pos_actual+1] = green
          main_data[pos_actual+2] = blue
        end
      end
      cnt -= 4
      main_video.frames[c] = main_data.pack('C*')
    end
  end

private
  attr_writer :main_video, :videos, :width, :height
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
          frames << frame.data
        end
      end
    end
    return frames
  end
end

