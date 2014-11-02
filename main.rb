#!/usr/bin/ruby

require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'Qt'
require_relative 'video_player'

$DEBUG              = true
$WIDTH              = 320
$HEIGHT             = 200
$FRAMES_PER_SECOND  = 100

class QtApp < Qt::MainWindow
  def initialize
    super

    setWindowTitle "Spatio-Temporal Video Transitions"

    @videoWidget = VideoPlayer.new(self)
    setCentralWidget @videoWidget

    resize $WIDTH, $HEIGHT

    center
    show
  end

  def center
    qdw = Qt::DesktopWidget.new

    screenWidth = qdw.width
    screenHeight = qdw.height

    x = (screenWidth - $WIDTH) / 2
    y = (screenHeight - $HEIGHT) / 2

    move x, y
  end
end

app = Qt::Application.new ARGV
QtApp.new
app.exec
