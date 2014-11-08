class VideoPlayer < Qt::Widget
  def initialize(parent)
    super(parent)

    setFocusPolicy Qt::StrongFocus

    initVideo
  end

  def initVideo
    puts "[NOTICE] Initializing Video #1" if $DEBUG == true
    video_1 = Video.new("./assets/MELT.MPG")
    puts "[NOTICE] Video Loaded: #{video_1.frames.length} Frames" if $DEBUG == true
    puts "[NOTICE] Initializing Video #2" if $DEBUG == true
    video_2 = Video.new("./assets/DELTA.MPG")
    puts "[NOTICE] Video Loaded: #{video_2.frames.length} Frames" if $DEBUG == true
    puts "[NOTICE] Initializing Swipe Viewport and STI Viewport" if $DEBUG == true
    @viewport = Viewport.new(320, 200)
    @sti_viewport = Viewport.new(320, 200, :black)
    puts "[NOTICE] Loading Video #1 into Video Playback" if $DEBUG == true
    @video_playback = VideoPlayback.new(video_1, 320, 200)
    puts "[NOTICE] Loading Video #2 into Video Playback" if $DEBUG == true
    @video_playback.videos << video_2
    puts "[NOTICE] Processing Video Transitions" if $DEBUG == true
    @video_playback.videoWipe(0, 0, 4)

    @sti_playback = STIPlayback.new(320, 200, video_1.frames_count)

    puts "[NOTICE] Initialization Complete" if $DEBUG == true
    @timer = Qt::Timer.new(self)
    connect(@timer, SIGNAL('timeout()'), self, SLOT('update()'))
    @time = Qt::Time.currentTime
    puts "[NOTICE] Current Time: #{@time.toString}" if $DEBUG == true
    @timer.start($FRAMES_PER_SECOND)
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
    @sti_viewport.frame = @sti_playback.getFrame(@sti_viewport.frame, @viewport.frame, @time.elapsed)
    image = Qt::Image.new(@sti_viewport.frame, @sti_viewport.width, @sti_viewport.height, Qt::Image.Format_RGB888)
    painter.drawImage 320, 0, image
  end
end

class Viewport
  attr_reader :frame, :width, :height

  def initialize(width, height, fill=nil)
    self.width = width
    self.height = height
    self.frame = Array.new(width*height*3, 0).pack('C*') if fill == :black
  end

  attr_writer :frame, :width, :height
end

class STIPlayback
  attr_reader :width, :height, :frames_count

  def initialize(width, height, frames_count)
    self.width = width
    self.height = height
    self.frames_count = frames_count
  end

  def getFrame(sti_frame, viewport_frame, time_elapsed)
    width_actual = self.width*3
    end_pos = height*width_actual
    main_data = sti_frame.unpack('C*')
    next_data = viewport_frame.unpack('C*')

    frame_number = (time_elapsed / $FRAMES_PER_SECOND) % self.frames_count

    row = frame_number
    pos_boundary = width
    row_next = width_actual*100
      row_actual = frame_number*width_actual
      for col in (0..pos_boundary)
        col_actual = col*3
        pos_actual = (col_actual-row_actual)

        pos_next = (col_actual-row_next)

        main_data[pos_actual] = next_data[pos_next]
        main_data[pos_actual+1] = next_data[pos_next+1]
        main_data[pos_actual+2] = next_data[pos_next+2]
      end
    return main_data.pack('C*')
  end

private
  attr_writer :width, :height, :frames_count
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
    puts "[NOTICE] Frame #: #{frame_number}" if $DEBUG == true
    main_video.frames[frame_number]
  end

  def videoWipe(start, video_id, speed)
    next_video = videos[video_id]
    width_actual = self.width*3
    end_pos = height*width_actual

    transition_time = (main_video.frames.size > next_video.frames.size ? next_video.frames.size : main_video.frames.size)-1

    puts "[NOTICE] Transition Time: #{transition_time}" if $DEBUG == true

    pos_boundary = width-1
    for c in 0..transition_time
      main_data = main_video.frames[c].unpack('C*')
      next_data = next_video.frames[c].unpack('C*')
      for row in (0..height)
        row_actual = row*width_actual
        for col in (width-1).downto(pos_boundary)
          col_actual = col*3
          pos_actual = (col_actual-row_actual)

          if next_data[pos_actual].nil?
            break
          end

          main_data[pos_actual] = next_data[pos_actual]
          main_data[pos_actual+1] = next_data[pos_actual+1]
          main_data[pos_actual+2] = next_data[pos_actual+2]
        end
      end
      pos_boundary -= speed
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
        raise "[ERROR] File does not contain a video stream" unless video_stream
        while frame = video_stream.decode ^ video_stream.resampler(:rgb24) do
          break unless frame.instance_of?(FFMPEG::VideoFrame)
          frames << frame.data
        end
      end
    end
    return frames
  end
end

