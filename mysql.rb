#!/usr/bin/env ruby
# encoding: utf-8

require "mysql2"
require "optparse"

host = username = password = connect_timeout = read_timeout = nil
opt = OptionParser.new
opt.on('-H VAL') {|val| host = val}
opt.on('-U VAL') {|val| username = val}
opt.on('-P VAL') {|val| password = val}
opt.on('-C VAL') {|val| connect_timeout = val.to_i}
opt.on('-R VAL') {|val| read_timeout = val.to_i}
opt.parse!(ARGV)

params = {
  :host => (host || "192.168.14.111"),
  :username => (username || "root"),
  :password => (password || "mysql"),
}
params[:connect_timeout] = connect_timeout if connect_timeout
params[:read_timeout] = read_timeout if read_timeout

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
  puts "Connect: OK"
else
  puts "Connect: NG"
  exit 0
end

target_db = "testtesttest"
target_db_exists = false
begin
  result = client.query("show databases;")
  puts "Show database: OK"
  result.each do |row|
    puts "#{row.inspect}"
    target_db_exists = true if row.values.include?(target_db)
  end
rescue => err
  puts "Show database: NG"
  puts err.message
  exit 0
end

begin
  result = client.query("show tables in mysql;")
  puts "Show tables: OK"
  result.each do |row|
    puts "#{row.inspect}"
  end
rescue => err
  puts "Show tables: NG"
  puts err.message
  exit 0
end

begin
  if target_db_exists
    result = client.query("drop database #{target_db};")
    puts "Drop database: OK"
  end
  result = client.query("create database #{target_db};")
  puts "Create database: OK"
  result = client.query("drop database #{target_db};")
  puts "Drop database: OK"
rescue => err
  puts "Create/Drop database: NG"
  puts err.message
  puts err.backtrace
  exit 0
end
