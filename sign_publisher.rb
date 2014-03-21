require 'net/https'
require 'json'
require 'mqtt'
require 'yaml'
require 'github_api'

class SignPublisher
  def self.get_pull_requests
    github_config = YAML::load(File.read("config/github.yml"))
    github = Github.new(oauth_token: github_config['token'])
puts github_config.inspect
puts "lol"
    xiissues = github.issues.list(:org => 'Xively', :filter => 'all', :auto_pagination => true)
    cissues = github.issues.list(:org => 'Cosm', :filter => 'all', :auto_pagination => true)

    xiprmsg = xiissues.map do |issue|
      if issue["pull_request"] && issue['repository']['private']
        "<amber>#{issue['repository']['name']}"
      end
    end.compact.uniq.sort

    cprmsg = cissues.map do |issue|
      if issue["pull_request"] && issue['repository']['private']
        "<amber>#{issue['repository']['name']}"
      end
    end.compact.uniq.sort

    content_msg = []
    if xiprmsg.any?
      content_msg << "<green>Xively pull requests (#{xiprmsg.size}) #{xiprmsg.join(', ')}"
    end
    if cprmsg.any?
      content_msg << "<green>Cosm pull requests (#{cprmsg.size}) #{cprmsg.join(', ')}"
    end

    content_msg = ["Pull Request Zero!!"] if content_msg.empty?

    msg = {
      :topic => 'pull_requests',
      :content => "<green>#{content_msg.join('; ')}"
    }

    return {:topic => "/pull_requests",
      :title => "<amber>Pull Requests",
      :message => "<green>#{content_msg.join('; ')}"}
  end

  def self.get_gh_status
    client = Net::HTTP.new('status.github.com', 443)
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_NONE

    message = {
      'good' => '<green>Battle station fully operational',
      'minor' => '<amber>Partial service outage',
      'minorproblem' => '<amber>Partial service outage',
      'majorproblem' => '<red>Major service outage'
    }

    client.get('/api/status.json') do |resp|
      status = JSON.parse(resp)['status']
      return {:topic => "/gh_status",
        :title => "<amber>Github Status",
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
        :title => "<amber>Stocks",
        :message => message}
    end
  end

  def self.run
    mqtt_config = YAML::load(File.read("config/mqtt.yml"))
    client = MQTT::Client.new({:username => mqtt_config["username"],
                                :password => mqtt_config["password"],
                                :remote_host => mqtt_config["host"]})

    messages = [get_gh_status, get_stocks, get_pull_requests]
    client.connect("2") do |c|
      messages.each do |message|
        c.publish(message[:topic], "#{message[:title]}: #{message[:message]}")
      end
    end
  end
end


SignPublisher.run
