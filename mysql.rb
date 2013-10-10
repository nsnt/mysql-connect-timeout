# encoding: utf-8

require 'mysql2'

client = nil
5.times do
  client = Mysql2::Client.new(:host => "192.168.14.111", :username => "root", :password => "mysql", :connect_timeout => 1)
end

if client
  puts "OK"
else
  puts "NG"
end
