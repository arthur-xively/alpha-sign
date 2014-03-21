require 'rubygems'
require 'socket'               # Get sockets from stdlib
require 'mqtt'
require 'yaml'


mqtt_config = YAML::load(File.read("mqtt.yml"))
sign_config = YAML::load(File.read("sign.yml"))

socket = TCPSocket.new sign_config["host"], sign_config["port"]

puts mqtt_config.inspect
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

def send_message(client, message)
  encoded_message = encode_message(message)
  puts encoded_message.inspect
  puts client.write(encoded_message).inspect
end

def read_message(client)
  (0x20..0x7E).each do |byte|
    pack = "\000\000\000\000\000\001Z00\002B#{byte.chr}\004"
    puts pack.inspect
    puts client.write(pack)
  end
end

# Subscribe example
client = MQTT::Client.new({:username => mqtt_config["username"],
                           :password => mqtt_config["password"],
                           :remote_host => mqtt_config["host"]})
client.connect("1") do |c|
  c.get(mqtt_config["topic"]) do |topic,message|
    send_message(socket, message)
  end
end

socket.close
