require 'rubygems'
require 'bundler'

Bundler.require(:default)

chart = Gchart.new(
            :type => "bar",
            :data => [[1,2,4,67,100,41,234],[45,23,67,12,67,300, 250]],
            :title => 'SD Ruby Fu level',
            :legend => ['test1','test2'],
            :bar_colors => 'ff0000,00ff00',
            :filename => "tmp/chart.png")

# Record file in filesystem
chart.file