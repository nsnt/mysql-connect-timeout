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

def mysql_retry(num, &blk)
  result = nil
  num.times do |time|
    begin
      result = blk.call
      break if result
    rescue Mysql2::Error => err_mysql2
      puts "#{err_mysql2.message}: #{time + 1} times"
    end
  end
  result
end

client = mysql_retry(3) do
  Mysql2::Client.new(params)
end

if client
  puts "Connect: OK"
else
  puts "Connect: NG"
  exit 0
end

result = mysql_retry(3) do
  client.query("show databases;")
end

target_db = "testtesttest"
target_db_exists = false
if result
  puts "Show databases: OK"
  result.each do |row|
    puts "#{row.inspect}"
    target_db_exists = true if row.values.include?(target_db)
  end
else
  puts "Show databases: NG"
  exit 0
end

result = mysql_retry(3) do
  client.query("show tables in mysql;")
end

if result
  puts "Show tables: OK"
  result.each do |row|
    puts "#{row.inspect}"
  end
else
  puts "Show tables: NG"
  exit 0
end

result = mysql_retry(3) do
  val = false
  if target_db_exists
    client.query("drop database #{target_db};")
    val = true
  else
    val = nil
  end
  val
end

if result
  puts "Drop database: OK"
elsif result.nil?
  puts "Need not to drop database '#{target_db}'"
else
  puts "Drop database: NG"
end

result = mysql_retry(3) do
  client.query("create database #{target_db};")
  true
end

if result
  puts "Create database '#{target_db}': OK"
else
  puts "Create database '#{target_db}': NG"
  exit 0
end

result = mysql_retry(3) do
  client.query("drop database #{target_db};")
  true
end

if result
  puts "Drop database '#{target_db}': OK"
else
  puts "Drop database '#{target_db}': NG"
  exit 0
end
