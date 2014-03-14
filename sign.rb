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
   0x1B.chr, '0', 'a', 'this is a message'
  ].join("")
end

def encode_message(message)
  message = ""
  message += add_header
  message += encode_body(message)
  message += add_footer
end

def send_message(client, message)
  encoded_message = encode_message(message)
  puts encoded_message.inspect
  puts client.write(encoded_message).inspect
end

def read_message(client)
  puts client.write("\000\000\000\000\000\001Z00BA\004")
end

# send_message(socket, "message here")
read_message(socket)
socket.close
