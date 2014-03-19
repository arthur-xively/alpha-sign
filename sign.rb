require 'rubygems'
require 'socket'               # Get sockets from stdlib
require 'mqtt'
require 'yaml'

socket = TCPSocket.new '192.168.60.8', 3001
credentials = YAML::load(File.read("mqtt.yml"))

puts credentials.inspect
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

def encode_message(message)
  encoding = ""
  encoding += add_header
  encoding += encode_body(message)
  encoding += add_footer
end

def set_memory(client, message)
  pack = ["\000\000\000\000\000\001",
          "Z00",
          "\002",
          "E$",
          'A', 'A',
          # 'L', sprintf("%04X", message.length), "FF00"
          "Hello BaZ"
          ].join("")
  puts pack.inspect
  puts client.write(pack)
end

def send_message(client, message)
  encoded_message = encode_message(message)
  puts encoded_message.inspect
  puts client.write(encoded_message).inspect
end

def send_beep(client)
  beep_function = "\000\000\000\000\000\001Z00\002E(1\004"
  puts beep_function.inspect
  puts client.write(beep_function).inspect
end

def read_message(client)
  (0x20..0x7E).each do |byte|
    pack = "\000\000\000\000\000\001Z00\002B#{byte.chr}\004"
    puts pack.inspect
    puts client.write(pack)
  end
end

# Subscribe example
# client = MQTT::Client.new({:username => credentials["username"],
#                            :password => credentials["password"],
#                            :remote_host => "v3mqtt.xively.com"})
# client.connect("1") do |c|
#   c.get('/test') do |topic,message|
#     send_message(socket, message)
#   end
# end

send_beep(socket)
socket.close
