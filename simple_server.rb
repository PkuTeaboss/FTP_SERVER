require 'socket'
require 'fileutils'

server = TCPServer.new 2000 # Server bound to port 2000

def do_user
 $client.puts "User Name:"
 $name = $client.recvfrom(20)[0]
 if $name[0..6] == 'TeaBoss'
 	$userFlag = ture
 	$client.puts "331 User Name is OK, Need Password:"
 	do_pass
 elsif $name[0..8] == 'anonymous'
 	$userFlag = true
 	$client.puts "230 Welcome Anonymous!"
 else
 	$client.puts "430 User Name Error"
 end
end

def do_pass
 $password = $client.recvfrom(20)[0]
 if $password[0..5] == '123456'
 	if $userFlag 
 		$logined = true
 		$client.puts "230 Welcome TeaBoss!"
 	else
 		$client.puts "530 Unqualified User"
 	end
 else
 	$client.puts "430 Password Error, type PASS to try again"
 end
end
	
def do_list
   $client.puts Dir.ls
end

def do_stor(filename)
  #if $new_client
    storFile = File.new(filename,"w")
    if storFile
      $client.puts "150 Opening Data Connection"
      while (1)
     	  buf = $client.recvfrom(1024)[0] #passiveClient
    	  if buf.length!=1
    	  	 storFile.write(buf)
    	  	 $client.puts "Get ; Go on"
    	  else
    		 break
    	  end
      end
      storFile.close
      $client.puts "226 Transfer Complete, #{filename} received"
    end
  #else
  #	$client.puts "You Need CMD PASV to Transfer Data"
  #end
end

def do_retr(filename)
	retrFile = File.open(filename, "r")
    if retrFile
      $client.puts "150 Opening Data Connection"
      retrFile.each {
      	|data| $client.puts data #passiveClient
      }
      retrFile.close
      $client.puts "226 Transfer Complete"
    else
      $client.puts "503 No Such File"
    end
end

def do_noop
 $client.puts "200 connection is OK"
end

def do_pwd
 $fileDir= Dir.getwd 
 $client.puts $fileDir
end

def do_cwd(path)
  Dir.chdir(path)
  $client.puts "Change dir path to #{path}"
  #$fileDir = path
end

def do_pasv
  $client.puts "127,0,0,1,99,18"
  # passive_server = TCPServer.new 9918＃
  # $new_client = passive_server.accept
end



$client = server.accept    # Wait for a client to connect
$client.puts "220 Wellcom to TeaBoss ftp!"
$client.puts "Time is #{Time.now}"
loop do
  
  cmd = $client.recvfrom(50)[0]
  puts "recv:#{cmd}"
  puts cmd.length
  case cmd[0..3]
  when "USER"
  	do_user
  when "PASS"
  	$client.puts "Password:"
  	do_pass
  when "LIST"
  	do_list
  when "PASV"
  	do_pasv
  when "RETR"
  	filename = cmd.split(" ")[1]
  	puts filename
  	do_retr(filename)
  when "STOR"
  	filename = cmd.split(" ")[1]
  	puts filename
  	do_stor(filename)
  when "NOOP"
  	do_noop
  when "QUIT"
  	$client.puts "client left! Bye!"
  	$client.close
  	break
  else
  	if cmd[0..2]=="PWD"
  		do_pwd
  	elsif cmd[0..2]=="CWD"
  		path = cmd.split(" ")[1]
  		do_cwd(path)
  	else
  	   $client.puts "ERROR 500:unkonw command"
    end
  end

end


# initial
# 



