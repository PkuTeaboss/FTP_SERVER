require 'socket'
require 'fileutils'
require 'optparse'
require 'ostruct'


class FTP

  def parse(args)

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

    end
    
    opt_parser.parse!(args)

    return options

  end    

  def initialize
      options = parse(ARGV)
      @port = options.port
      @dir = options.dir
      @host = options.host
      @logined = {}    
      @name_client = {}  
      @users = {"TeaBoss"=>"123456","anonymous"=>""}
      @clientArray = []
      @dataSocketHash = {}
      @serverSocket = TCPServer.new(@host, @port)     
      @clientArray << @serverSocket
      runMain
  end

  def not_logined(client)
    if @logined[client] != true
      client.puts "530 Unqualified User. Use cmd USER to login"
      return true  
    else
      return false
    end
  end

  def do_user(client)
   if @logined[client] 
    puts "230 Already logined"
   else 
     client.puts "User Name:"
     name = client.gets.chomp
     if @users.keys.include? name
      @name_client[client] = name
      client.puts "331 User Name is OK, Need Password:"
      do_pass(client)
     else
      client.puts "430 User Name Error"
     end
   end
  end

  def do_pass(client)
   password = client.gets.chomp
   if @name_client[client] != nil 
     if password == @users[@name_client[client]]
      @logined[client] = true
      client.puts "230 Welcome #{@name_client[client]}!"
     else
      client.puts "430 Password Error, use PASS to try again"
     end
   else
     $client.puts "Use cmd USER first"
   end
  end
    
  def do_cwd(client,path)
    if path == nil
      puts "No path info"
    else
      if File.directory?(path)
        puts path
        Dir.chdir(path) 
        client.puts "Change dir path to #{path}"
      else
        client.puts "Invalid directory"
      end
    end
  end

  def do_pasv(client)
    prng = Random.new(client.peeraddr[1])
    dataPort = prng.rand(1025..65535)
    dataSocket = TCPServer.new(dataPort)
    @dataSocketHash[client] = dataSocket
    client.puts "227 Entering passive mode (127,0,0,1,#{dataPort/256},#{dataPort%256})"
  end

  def do_list(client)
    if @dataSocketHash[client] != nil
      clientData = @dataSocketHash[client].accept
      pwd = Dir.getwd
      clientData.puts Dir.entries(pwd)
      clientData.close
    else
      client.puts "Use PASV before transfering Data"
    end
  end

  def do_stor(client,filename)
    if filename == nil
      client.puts "No filename"
    else
      if @dataSocketHash[client] != nil
        clientData = @dataSocketHash[client].accept
        storFile = File.new(filename,"w")
        if storFile
          client.puts "150 Opening Data Connection"
          # while (1)
          #   buf = clientData.recvfrom(1024)[0]
          #   if buf.length!=1
          #      storFile.write(buf)
          #   else
          #    break
          #   end
          # end
          storFile.syswrite(clientData.read)
          clientData.close
          client.puts "226 Transfer Complete, #{filename} stored"
        else
          client.puts "Unable to open file"
        end
      else
        client.puts "Use PASV before transfering Data"
      end
    end
  end


  def do_retr(client,filename)
    if !File.readable?(filename)
      client.puts "503 No Such File"
    else
      if @dataSocketHash[client] != nil
        clientData = @dataSocketHash[client].accept
        client.puts "150 Opening Data Connection"
        file = open(File.absolute_path(filename))
        clientData.puts(file.read)
        clientData.close
        client.puts "226 Transfer Complete, #{filename} retrieved"
      else
        client.puts "Use PASV before transfering Data"
      end
    end
  end
  # def do_noop(client)
  #  $client.puts "200 connection is OK"
  # end
  def do_quit(client)
    puts "Client #{client.peeraddr[2]}|#{client.peeraddr[1]} left."
    @clientArray.delete(client)
    @dataSocketHash.delete(client)
    @logined[client] = false
    @name_client.delete(client)
  end



  def parse_cmd(client,cmd)
    case cmd[0]
      when "USER"
        do_user(client)
      when "PASS"
        do_pass(client)
      when "PWD"
        client.puts Dir.getwd
      when "CWD"
        do_cwd(client,cmd[1])
      when "LIST" 
        do_list(client) if !not_logined(client)
      when "PASV"
        do_pasv(client) if !not_logined(client)
      when "RETR"
        do_retr(client,cmd[1]) if !not_logined(client)
      when "STOR"
        do_stor(client,cmd[1]) if !not_logined(client)
      when "QUIT"
        do_quit(client)
        client.close
    end 
  end 

  def runMain
    loop do
      if select(@clientArray , nil, nil, nil)
          select(@clientArray, nil, nil, nil)[0].each do |client| 
            if client == @serverSocket
              newclient = @serverSocket.accept
              @clientArray << newclient
              puts "Client #{newclient.peeraddr[2]}|#{newclient.peeraddr[1]} connected."
              newclient.puts("220 Welcome to TeaBoss FTP.")
            else
              if client.eof?
                do_quit(client)
                client.close
              else
                cmd = client.gets.chomp.split(" ")
                parse_cmd(client,cmd)
              end
            end
          end
      end
    end
  end

end 

Myserver = FTP.new
