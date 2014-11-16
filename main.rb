require 'optparse'
require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'Qt'
require_relative 'video_player'

$DEBUG              = true
$WIDTH              = 640
$HEIGHT             = 200
$FRAMES_PER_SECOND  = 100

class QtApp < Qt::MainWindow
  def initialize
    super

    setWindowTitle "Spatio-Temporal Video Transitions"

    @videoWidget = VideoPlayer.new(self)
    setCentralWidget @videoWidget
    setFixedSize($WIDTH, $HEIGHT)
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

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [options] video"

  opts.on("-v", "--videos a,b", Array, "[REQUIRED] List of videos to process") do |v|
    $options[:videos] = v
  end
  opts.on("-s", "--swipe [TYPE]", [:right2left, :left2right], "Select swipe type (right2left, left2right)") do |s|
    if s.nil?
          $options[:swipe] = {right2left: true}
    else
      $options[:swipe] = s
    end
  end
  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end.parse!

raise OptionParser::MissingArgument if $options[:videos].nil?

app = Qt::Application.new ARGV
QtApp.new
app.exec
