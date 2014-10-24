#!/usr/bin/ruby

require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'Qt'

WIDTH = 250
HEIGHT = 150

class QtApp < Qt::Widget

    def initialize
        super

        setWindowTitle "Center"
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

app = Qt::Application.new ARGV
QtApp.new
app.exec

File.open("./earth.avi") do |io|
  FFMPEG::Reader.open(io) do |reader|
      first_video_stream = reader.streams.select { |s| s.type == :video }.first
      raise "File does not contain a video stream" unless first_video_stream
      while frame = first_video_stream.decode do
        File.open("./output-%03.3f.bmp" % frame.timestamp, "wb") do |output|
          output.write(frame.to_bmp)
        end
      end
  end
end
