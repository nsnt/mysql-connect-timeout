#!/usr/bin/env ruby
# encoding: utf-8

require "mysql2"

client = nil
5.times do |time|
  begin
    client = Mysql2::Client.new(:host => "192.168.14.111", :username => "root", :password => "mysql", :connect_timeout => 1)
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
