require 'socket'
require 'fileutils'
require 'optparse'
require 'ostruct'

  
options = OpenStruct.new
options.port = 2000
options.host = "127.0.0.1"
options.dir = Dir.getwd

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: 001-ftp-server/myftp.rb [options]"

  opts.on_head("-p","--port=PORT","listen port") do |port|
    if port.to_i.is_a? Fixnum
      options.port = port
    else
      puts "Invaild port, using defalut 2000 instead"
    end
  end

  address_list = ["127.0.0.1"]
  Socket.ip_address_list.each {|addrinfo| address_list << addrinfo.ip_address}
  opts.on("--host=HOST","binding address") do |host|
    if address_list.include? host
      options.host = host
    else
      puts "Invalid host address, using defalut 127.0.0.1 instead"
    end
  end

  opts.on("--dir==DIR","change current directory") do |dir|
    if File.directory?(dir) 
      options.dir = dir
    else
      puts "Invalid directory, using PWD instead"
    end
  end

  opts.on_tail("-h","print help") do
    puts opts
  end

end.parse!

puts options