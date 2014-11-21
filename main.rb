require 'optparse'
require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'Qt'
require 'histogram/array'
require_relative 'video_player'

$DEBUG              = true
$WIDTH              = 320
$HEIGHT             = 200
$FRAME_WIDTH        = $WIDTH*2
$FRAME_HEIGHT       = $HEIGHT
$FRAMES_PER_SECOND  = 100
$TRANSITION_STEP    = 4

class QtApp < Qt::MainWindow
  def initialize
    super

    setWindowTitle "Spatio-Temporal Video Transitions"

    @videoWidget = VideoPlayer.new(self)
    setCentralWidget @videoWidget
    setFixedSize($FRAME_WIDTH, $FRAME_HEIGHT)
    resize $FRAME_WIDTH, $FRAME_HEIGHT

    center
    show
  end

  def center
    qdw = Qt::DesktopWidget.new

    screenWidth = qdw.width
    screenHeight = qdw.height

    x = (screenWidth - $FRAME_WIDTH) / 2
    y = (screenHeight - $FRAME_HEIGHT) / 2

    move x, y
  end
end

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [options] --videos path_to_video1,path_to_video2"

  opts.on("-v", "--videos a,b", Array, "[REQUIRED] List of videos to process.") do |v|
    $options[:videos] = v
  end
  opts.on("-n", "--no-render", "Computes wipe and displays STI without frame-by-frame rendering.") do |r|
    if r.nil?
      $options[:no_render] = false
    else
      $options[:no_render] = true
    end
  end
  opts.on("-s", "--swipe [TYPE]", [:right2left, :left2right, :up2down, :down2up, :iris], "Select swipe type (right2left, left2right, up2down, down2up, iris).") do |s|
    if s.nil?
      $options[:swipe] = {right2left: true}
    else
      $options[:swipe] = s
    end
  end
  opts.on('-h', '--help', 'Displays Help.') do
    puts opts
    exit
  end
end.parse!

raise OptionParser::MissingArgument if $options[:videos].nil?

app = Qt::Application.new ARGV
QtApp.new
app.exec
