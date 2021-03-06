# Spatio-Temporal Video Transformation

Specifically this is for a course assignment written in Ruby for CMPT365 at Simon Fraser University.

### Ubuntu 14.04 Required Software/Libraries

#### Qt 4.X
	apt-get install cmake qt-sdk libqt4 libqt4-dev


#### Ruby 2.1.1 (through Ruby Version Manager, RVM)
	sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
	curl -L https://get.rvm.io | bash -s stable
	source ~/.rvm/scripts/rvm
	echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc
	rvm install 2.1.1
	rvm use 2.1.1 --default
	ruby -v

### Running the Application
#### Run Bundler
	bundle install

#### Run Ruby Script
	ruby ./cmpt365_p03.rb

### Ways to Run
#### Swiping from Left-to-Right
	ruby main.rb --swipe left2right --videos ./assets/DELTA.MPG,./assets/MELT.MPG
#### Swiping from Right-to-Left
	ruby main.rb --swipe right2left --videos ./assets/DELTA.MPG,./assets/MELT.MPG
#### Swiping from Up-to-Down
	ruby main.rb --swipe up2down --videos ./assets/DELTA.MPG,./assets/MELT.MPG
#### Swiping from Down-to-Up
	ruby main.rb --swipe down2up --videos ./assets/DELTA.MPG,./assets/MELT.MPG
#### Swiping as an opening Iris
	ruby main.rb --swipe iris --videos ./assets/DELTA.MPG,./assets/MELT.MPG
