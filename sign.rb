require 'socket'               # Get sockets from stdlib

socket = TCPSocket.new '192.168.60.8', 3001

class String
  def ord
    bytes.to_a.first
  end
end

def add_header
  [0x00, 0x00, 0x00, 0x00, 0x00,
   0x01,
   'Z'.ord,
   '0'.ord, '0'.ord,
   0x02].pack("C*")
end

def add_footer
  [0x04].pack("C")
end

def encode_body(message)
  s = ['A',
   'A',
   0x1B.chr, '0', 'a', message
  ].join("")
end

def initiate_transfer(client)
  puts add_header.inspect
  puts client.write(add_header)
end

def encode_message(message)
  encoding = ""
  encoding += encode_body(message)
  encoding += add_footer
end

def set_memory(client, message)
  pack = ['A', 'A', 'L', sprintf("%04X", message.length), "FF00"].join("")
  puts pack.inspect
  puts client.write(pack)
end

def send_message(client, message)
  encoded_message = encode_message(message)
  puts encoded_message.inspect
  puts client.write(encoded_message).inspect
end

def read_message(client)
  puts client.write("\000\000\000\000\000\001Z00\002BA\004")
end

message = "this is a message"
initiate_transfer(socket)
set_memory(socket, message)
send_message(socket, message)
# read_message(socket)
socket.close
