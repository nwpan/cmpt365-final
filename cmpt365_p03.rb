#!/usr/bin/ruby

require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'Qt'

WIDTH   = 320
HEIGHT  = 200

class QtApp < Qt::MainWindow
  def initialize
    super

    setWindowTitle "Spatio-Temporal Video Transitions"

    @videoWidget = VideoPlayer.new(self)
    setCentralWidget @videoWidget

    resize WIDTH, HEIGHT

    center
    show
  end

  def center
    qdw = Qt::DesktopWidget.new

    screenWidth = qdw.width
    screenHeight = qdw.height

    x = (screenWidth - WIDTH) / 2
    y = (screenHeight - HEIGHT) / 2

    move x, y
  end
end

class VideoPlayer < Qt::Widget
  def initialize(parent)
    super(parent)

    @timer = Qt::Timer.new(self)
    connect(@timer, SIGNAL('timeout()'), self, SLOT('update()'))
    @timer.start(1000)
    setFocusPolicy Qt::StrongFocus

    initVideo
  end

  def initVideo
    @frames = getFrames
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
    #@frames.each do |frame|
      puts @time.elapsed / 1000
      frame = @frames[@time.elapsed / 1000]
      image = Qt::Image.new(frame.data, frame.width, frame.height, Qt::Image.Format_RGB888)
      painter.drawImage 0, 0, image
    #end
  end

  def getFrames
    frames = Array.new
    File.open("./assets/earth.avi") do |io|
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

  def time
    t = Time.now
    result = yield
    puts "\nCompleted in #{Time.now - t} seconds"
    result
  end
end


app = Qt::Application.new ARGV
QtApp.new
app.exec
