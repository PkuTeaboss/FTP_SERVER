require 'socket'

s = TCPSocket.new 'localhost', 2000
2.times do
 line = s.gets
 puts line
end
loop do
 str = STDIN.gets
 if str == "QUIT"
 	break
 end
 s.puts str
 line = s.gets # Read lines from socket
 puts line         # and print them
end
s.close             # close socket when done