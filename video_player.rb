class VideoPlayer < Qt::Widget
  def initialize(parent)
    super(parent)

    setFocusPolicy Qt::StrongFocus

    initVideo
  end

  def initVideo
    videos = []
    $options[:videos].each_with_index do |file, index|
      puts "[NOTICE] Initializing Video #{index}" if $DEBUG == true
      video = Video.new(file)
      videos << video
      puts "[NOTICE] Video Loaded: #{video.frames.length} Frames" if $DEBUG == true
    end

    puts "[NOTICE] Initializing Swipe Viewport and STI Viewport" if $DEBUG == true
    @viewport = Viewport.new($WIDTH, $HEIGHT)
    @sti_viewport = Viewport.new($WIDTH, $HEIGHT, :black)

    puts "[NOTICE] Loading Video #1 into Video Playback" if $DEBUG == true
    @video_playback = VideoPlayback.new(videos.first, $WIDTH, $HEIGHT)

    videos.drop(1).each_with_index do |video, index|
      puts "[NOTICE] Loading Video #{index} into Video Playback" if $DEBUG == true
      @video_playback.videos << video
    end

    if @video_playback.videos.size >= 1
      puts "[NOTICE] Processing Video Transitions" if $DEBUG == true
      @video_playback.videoWipe(0, 0, 0, $TRANSITION_STEP)
    end

    @sti_playback = STIPlayback.new($WIDTH, $HEIGHT, @video_playback.frame_count)

    puts "[NOTICE] Initialization Complete" if $DEBUG == true
    @timer = Qt::Timer.new(self)
    connect(@timer, SIGNAL('timeout()'), self, SLOT('update()'))
    @time = Qt::Time.currentTime
    puts "[NOTICE] Current Time: #{@time.toString}" if $DEBUG == true

    if $options[:no_render]
      for frame_number in (0..@sti_playback.frames_count)
        if @sti_playback.status
          @viewport.frame = @video_playback.getFrame(@sti_playback.frames_count)
        else
          @viewport.frame = @video_playback.getFrame(frame_number)
          @sti_viewport.frame = @sti_playback.getFrame(@sti_viewport.frame, @viewport.frame, frame_number)
        end
      end
    end
    @timer.start($FRAMES_PER_SECOND)
  end

  def paintEvent event
    painter = Qt::Painter.new
    painter.begin self
    if @sti_playback.status
      drawSTIFrame painter
      @timer.stop
    elsif !$options[:no_render]
      drawFrames painter
    end
    painter.end
  end

  def drawFrames painter
    painter.setPen Qt::NoPen
    frame_number = (@time.elapsed / $FRAMES_PER_SECOND) % @sti_playback.frames_count
    @viewport.frame = @video_playback.getFrame(frame_number)
    image = Qt::Image.new(@viewport.frame, @viewport.width, @viewport.height, Qt::Image.Format_RGB888)
    painter.drawImage 0, 0, image
    @sti_viewport.frame = @sti_playback.getFrame(@sti_viewport.frame, @viewport.frame, frame_number)
    image = Qt::Image.new(@sti_viewport.frame, @sti_viewport.width, @sti_viewport.height, Qt::Image.Format_RGB888)
    painter.drawImage $WIDTH, 0, image
  end

  def drawSTIFrame painter
    painter.setPen Qt::NoPen
    @viewport.frame = @video_playback.getFrame(@sti_playback.frames_count)
    image = Qt::Image.new(@viewport.frame, @viewport.width, @viewport.height, Qt::Image.Format_RGB888)
    painter.drawImage 0, 0, image
    image = Qt::Image.new(@sti_viewport.frame, @sti_viewport.width, @sti_viewport.height, Qt::Image.Format_RGB888)
    painter.drawImage $WIDTH, 0, image
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
  attr_reader :width, :height, :frames_count, :status

  def initialize(width, height, frames_count)
    self.width = width
    self.height = height
    self.frames_count = frames_count
    self.status = false
  end

  def getFrame(sti_frame, viewport_frame, frame_number)
    width_actual = self.width*3
    end_pos = height*width_actual
    main_data = sti_frame.unpack('C*')
    next_data = viewport_frame.unpack('C*')

    if frame_number == self.frames_count-1
      self.status = true
    end

    row = frame_number
    pos_boundary = width
    row_next = width_actual*(height/2)
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
  attr_writer :width, :height, :frames_count, :status
end

class VideoPlayback
  attr_reader :main_video, :videos, :width, :height, :frame_count

  def initialize(main_video, width, height)
    self.width = width
    self.height = height
    self.main_video = main_video
    self.videos = Array.new
    self.frame_count = @main_video.frames.size
    @count = 0
  end

  def getFrame(frame_number)
    return nil if main_video.nil? || main_video.frames_count <= 0
    puts "[NOTICE] Frame #: #{frame_number}" if $DEBUG == true
    main_video.frames[frame_number]
  end

  def videoWipe(start_v1, start_v2, video_id, speed)
    next_video = videos[video_id]
    width_actual = self.width*3
    end_pos = height*width_actual

    case $options[:swipe]
      when :up2down
        pos_boundary = 0
        incr = 1
        transition_frame_count = self.height / speed
        puts "[NOTICE] Swipe Mode: Up-to-Down" if $DEBUG == true
      when :down2up
        pos_boundary = self.height-1
        incr = -1
        transition_frame_count = self.height / speed
        puts "[NOTICE] Swipe Mode: Down-to-Up" if $DEBUG == true
      when :iris
        rmax = Math.sqrt(((self.width-1)/2)**2+((self.height-1)/2)**2)
        transition_frame_count = (self.height / speed)
        puts "[NOTICE] Swipe Mode: Iris" if $DEBUG == true
      when :left2right
        pos_boundary = 0
        incr = 1
        transition_frame_count = self.width / speed
        puts "[NOTICE] Swipe Mode: Left-to-Right" if $DEBUG == true
      else
        pos_boundary = self.width-1
        incr = -1
        transition_frame_count = self.width / speed
        puts "[NOTICE] Swipe Mode: Right-to-Left" if $DEBUG == true
    end
    self.frame_count = transition_frame_count

    puts "[NOTICE] Transition Frame Count: #{transition_frame_count}" if $DEBUG == true

    for c in 0..transition_frame_count
      main_data = main_video.frames[c+start_v1].unpack('C*')
      next_data = next_video.frames[c+start_v2].unpack('C*')
      if [:up2down, :down2up, :iris].include? $options[:swipe]
        if $options[:swipe] == :up2down
          for row in (0..pos_boundary)
            row_actual = row*width_actual
            for col in (0..self.width-1)
              col_actual = col*3
              pos_actual = (col_actual+row_actual)

              if next_data[pos_actual].nil?
                break
              end

              main_data[pos_actual] = next_data[pos_actual]
              main_data[pos_actual+1] = next_data[pos_actual+1]
              main_data[pos_actual+2] = next_data[pos_actual+2]
            end
          end
          pos_boundary += incr * speed
        elsif $options[:swipe] == :down2up
          for row in (self.height-1).downto(pos_boundary)
            row_actual = row*width_actual
            for col in (0..self.width-1)
              col_actual = col*3
              pos_actual = (col_actual+row_actual)

              if next_data[pos_actual].nil?
                break
              end

              main_data[pos_actual] = next_data[pos_actual]
              main_data[pos_actual+1] = next_data[pos_actual+1]
              main_data[pos_actual+2] = next_data[pos_actual+2]
            end
          end
          pos_boundary += incr * speed
        elsif $options[:swipe] == :iris
          rT = (c+1)/(transition_frame_count.to_f)*rmax
          for row in (0..self.height-1)
            row_actual = row*width_actual
            for col in (0..self.width-1)
              r = Math.sqrt(((col-(self.width-1)/2)/2)**2+((row-(self.height-1)/2)/2)**2)
              col_actual = col*3
              pos_actual = (col_actual+row_actual)

              if next_data[pos_actual].nil?
                break
              end

              if r < rT
                main_data[pos_actual] = next_data[pos_actual]
                main_data[pos_actual+1] = next_data[pos_actual+1]
                main_data[pos_actual+2] = next_data[pos_actual+2]
              end
            end
          end
        end
      else
        for row in (0..height)
          row_actual = row*width_actual
          if $options[:swipe]== :left2right
            for col in (0..pos_boundary)
              col_actual = col*3
              pos_actual = (col_actual-row_actual)

              if next_data[pos_actual].nil?
                break
              end

              main_data[pos_actual] = next_data[pos_actual]
              main_data[pos_actual+1] = next_data[pos_actual+1]
              main_data[pos_actual+2] = next_data[pos_actual+2]
            end
          else
            for col in (self.width-1).downto(pos_boundary)
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
        end
        pos_boundary += incr * speed
      end
      main_video.frames[c] = main_data.pack('C*')
    end
    for c in transition_frame_count..self.frame_count-1
      next_data = next_video.frames[c+start_v2].unpack('C*')
      main_video.frames[c+start_v1] = next_data
    end
  end

private
  attr_writer :main_video, :videos, :width, :height, :frame_count
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

