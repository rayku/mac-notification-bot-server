require 'rubygems'
require 'daemons'

pwd = Dir.pwd
Daemons.run_proc('notification-bot-server', {:dir_mode => :normal, :dir => "/opt/pids/sinatra"}) do
  Dir.chdir(pwd)
  exec "RACK_ENV=production ruby server.rb -p 5678"
end
