#!/usr/bin/env ruby
# encoding: utf-8

require "socket"
require "mysql2"
require "optparse"

TIMEOUT = 1.0

host = username = password = connect_timeout = read_timeout = write_timeout = nil
opt = OptionParser.new
opt.on('-H VAL') {|val| host = val}
opt.on('-U VAL') {|val| username = val}
opt.on('-P VAL') {|val| password = val}
opt.on('-C VAL') {|val| connect_timeout = val.to_f}
opt.on('-R VAL') {|val| read_timeout = val.to_f}
opt.on('-W VAL') {|val| write_timeout = val.to_f}
opt.parse!(ARGV)

params = {
  :host => (host || "192.168.14.111"),
  :username => (username || "root"),
  :password => (password || "mysql"),
}
params[:connect_timeout] = connect_timeout if connect_timeout
params[:read_timeout] = read_timeout if read_timeout
params[:write_timeout] = write_timeout if write_timeout

def timeout_val(timeout)
  secs = Integer(timeout)
  usecs = Integer((timeout - secs) * 1_000_000)
  optval = [secs, usecs].pack("l_2")
  return optval
end

def conn_acceptable?(host, port=3306, r_timeout=TIMEOUT, s_timeout = TIMEOUT)
  addr = Socket.getaddrinfo(host, nil)
  sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

  sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeout_val(r_timeout))
  sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, timeout_val(s_timeout))

  sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))

  return sock
end

def my_retry(num, &blk)
  result = nil
  num.times do |time|
    begin
      result = blk.call
      break if result
    rescue Mysql2::Error => err_mysql2
      puts "Mysql2::Error #{err_mysql2.message}: #{time + 1} times"
    rescue => err
      puts "#{err.message}: #{time + 1} times"
    end
  end
  result
end

conn = my_retry(3) do
  require"pry";require"pry-debugger";binding.pry
  conn_acceptable?(params[:host], 3306, params[:read_timeout], params[:write_timeout])
end

if conn
  puts "Socket connect: OK"
else
  puts "Socket connect: NG"
  puts "Going on .."
end

client = my_retry(3) do
  Mysql2::Client.new(params)
end

if client
  puts "Connect: OK"
else
  puts "Connect: NG"
  exit 0
end

result = my_retry(3) do
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

result = my_retry(3) do
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

result = my_retry(3) do
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

result = my_retry(3) do
  client.query("create database #{target_db};")
  true
end

if result
  puts "Create database '#{target_db}': OK"
else
  puts "Create database '#{target_db}': NG"
  exit 0
end

result = my_retry(3) do
  client.query("drop database #{target_db};")
  true
end

if result
  puts "Drop database '#{target_db}': OK"
else
  puts "Drop database '#{target_db}': NG"
  exit 0
end
