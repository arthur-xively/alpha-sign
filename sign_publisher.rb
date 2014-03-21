require 'rubygems'
require 'net/https'
require 'json'
require 'mqtt'
require 'yaml'

class SignPublisher
  def self.get_gh_status
    client = Net::HTTP.new('status.github.com', 443)
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_NONE

    message = {
      'good' => 'Battle station fully operational',
      'minor' => 'Partial service outage',
      'minorproblem' => 'Partial service outage',
      'majorproblem' => 'Major service outage'
    }

    client.get('/api/status.json') do |resp|
      status = JSON.parse(resp)['status']
      return {:topic => "/gh_status",
        :title => "Github Status",
        :message => message[status]}
    end
  end

  def self.get_stocks
    stocks_config = YAML::load(File.read("config/stocks.yml"))
    tickers = stocks_config["symbols"].join(",")
    client = Net::HTTP.new('finance.google.com')
    request = client.get("http://finance.google.com/finance/info?client=ig&q=#{tickers}") do |resp|
      data = JSON.parse(resp.sub('// ', ''))
      message = data.map { |stock|
        "<amber>#{stock["t"]} #{stock["l_cur"]} <#{stock['c'].to_f < 0 ? 'red>' : 'green>+'}#{stock['cp']}%"
      }.join('   ')
      return {:topic => "/stocks",
        :title => "Stocks",
        :message => message}
    end
  end

  def self.run
    mqtt_config = YAML::load(File.read("config/mqtt.yml"))
    client = MQTT::Client.new({:username => mqtt_config["username"],
                                :password => mqtt_config["password"],
                                :remote_host => mqtt_config["host"]})

    messages = [get_gh_status, get_stocks]
    client.connect("2") do |c|
      messages.each do |message|
        c.publish(message[:topic], "#{message[:title]}: #{message[:message]}")
      end
    end
  end
end


SignPublisher.run
