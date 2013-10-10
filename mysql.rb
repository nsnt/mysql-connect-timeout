#!/usr/bin/env ruby
# encoding: utf-8

require "mysql2"
require "optparse"

host = username = password = connect_timeout = nil
opt = OptionParser.new
opt.on('-H VAL') {|val| host = val}
opt.on('-U VAL') {|val| username = val}
opt.on('-P VAL') {|val| password = val}
opt.on('-T VAL') {|val| connect_timeout = val.to_i}
opt.parse!(ARGV)

params = {
  :host => (host || "192.168.14.111"),
  :username => (username || "root"),
  :password => (password || "mysql"),
  :connect_timeout => (connect_timeout || 1)
}

client = nil
5.times do |time|
  begin
    client = Mysql2::Client.new(params)
    break if client
  rescue Mysql2::Error => err_mysql2
    puts "#{err_mysql2.message}: #{time + 1} times"
  end
end

if client
  puts "OK"
else
  puts "NG"
end
