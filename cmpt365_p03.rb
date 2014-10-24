#!/usr/bin/ruby

require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'Qt'

WIDTH = 800
HEIGHT = 600

class QtApp < Qt::MainWindow
  def initialize
    super

    setWindowTitle "Spatio-Temporal Video Transitions"

    @videoWidget = Video.new(self)
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

class Video < Qt::Widget
  def initialize(parent)
    super(parent)

    setFocusPolicy Qt::StrongFocus

    initVideo
  end

  def initVideo
    @frames = getFrames
  end

  def paintEvent event
    painter = Qt::Painter.new
    painter.begin self
    drawObjects painter
    painter.end
  end

  def drawObjects painter
    painter.setPen Qt::NoPen
    @frames.each do |frame|
      image = Qt::Image.new(frame.data, frame.width, frame.height, Qt::Image.Format_RGB888)
      painter.drawImage 0, 0, image
    end
  end

  def getFrames
    frames = Array.new
    File.open("./assets/earth.avi") do |io|
      FFMPEG::Reader.open(io) do |reader|
        video_stream = reader.streams.select { |s| s.type == :video }.first
        raise "File does not contain a video stream" unless video_stream
        while frame = video_stream.decode ^ video_stream.resampler(:rgb24) do
          frames << frame
          break
        end
      end
    end
    return frames
  end
end


app = Qt::Application.new ARGV
QtApp.new
app.exec
