###############################################################################
##                                                                           ##
## The MIT License (MIT)                                                     ##
##                                                                           ##
## Copyright (c) 2014 AT&T Inc.                                              ##
##                                                                           ##
## Permission is hereby granted, free of charge, to any person obtaining     ##
## a copy of this software and associated documentation files                ##
## (the "Software"), to deal in the Software without restriction, including  ##
## without limitation the rights to use, copy, modify, merge, publish,       ##
## distribute, sublicense, and/or sell copies of the Software, and to permit ##
## persons to whom the Software is furnished to do so, subject to the        ##
## conditions as detailed in the file LICENSE.                               ##
##                                                                           ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   ##
## OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                ##
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    ##
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      ##
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT ##
## OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR  ##
## THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                ##
##                                                                           ##
###############################################################################
#!/usr/bin/env ruby

require 'net/smtp'
require 'optparse'
require 'yaml'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: notify.rb [options]"

  opts.on('-u', '--username NAME', 'OpenStack admin username') { |v| options[:user_name] = v }
  opts.on('-t', '--tenant NAME', 'OpenStack admin tenant') { |v| options[:tenant_name] = v }
  opts.on('-p', '--password PASSWORD', 'OpenStack admin user password') { |v| options[:user_password] = v }
  opts.on('-a', '--authurl AUTHURL', 'Keystone auth URL') { |v| options[:auth_url] = v }
  opts.on('-s', '--subject SUBJECT', 'Subject of the message') { |v| options[:subject] = v }
  opts.on('-m', '--message MESSAGE', 'Mesage to users or file containing message') { |v| options[:message] = v }
  opts.on('-d', '--dry', '') { |v| options[:dry] = v }
  opts.on('-v', '--verbose', '') { |v| options[:verbose] = v }
  opts.on('-c', '--config CONF_FILE', 'Configuration file') { |v| options[:config] = v }
end

begin
  optparse.parse!
  required = [:user_name, :tenant_name, :user_password, :auth_url, :message, :subject]
  missing = required.select{ |option| options[option].nil? }
  if not missing.empty?
    puts "You must provide options: #{missing.join(', ')}"
    puts optparse
    exit
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

if options[:config]
  if File.exists?(options[:config])
    conf = YAML.load_file()
  else
    abort("Cannot read config file")
  end
else
  conf = YAML.load_file('/etc/occam/os_users_notify.yaml')
end

if File.exists?(options[:message])
  options[:message] = File.read(options[:message])
end

blacklist = [
  'alt_demo@alt_demo',
  'cinder@localhost',
  'demo@demo',
  'foo@bar.com',
  'glance@localhost',
  'neutron@localhost',
  'nova@localhost',
]

service_tenant = `keystone \
                    --os-username #{options[:user_name]} \
                    --os-tenant-name #{options[:tenant_name]} \
                    --os-password #{options[:user_password]} \
                    --os-auth-url #{options[:auth_url]} \
                    tenant-get services`

if service_tenant =~ /^\|\s+id\s+\|\s+(.*?)\s+\|$/m
  tenant_id = $1
else
  abort("Something went wrong, cannot get service tenant id")
end

if !options[:dry]
  user_list = `keystone \
              --os-username #{options[:user_name]} \
              --os-tenant-name #{options[:tenant_name]} \
              --os-password #{options[:user_password]} \
              --os-auth-url #{options[:auth_url]} \
              user-list`

else
  user_list =<<-MSG
+----------------------------------+-----------------------------------+---------+-----------------------------------+
|                id                |                name               | enabled |               email               |
+----------------------------------+-----------------------------------+---------+-----------------------------------+
| 4f875d48d4a24e6397c67bb3df18dc21 |                kamil              |   True  |    kswiatkowski@mirantis.com      |
| 11055a63911449cf8cef5c745e3a6317 |              alt_demo             |   True  |         alt_demo@alt_demo         |
| ec74e0113fa54ddeb01eac74ddd7702c |               tomasz              |   True  |      tnapierala@mirantis.com      |
+----------------------------------+-----------------------------------+---------+-----------------------------------+
MSG
end

if $? != 0
  abort("Cannot get keystone users list")
end

count = 0
users = []
header = []
user_list.split(/\n/).each do |line|
  if line =~ /\|\s+(.*?)\s+\|\s+(.*?)\s+\|\s+(.*?)\s+\|\s+(.*?)\s+\|/
    if count == 0
      header = [$1,$2,$3,$4]
      count += 1
    else
      users << { header[0].to_sym => $1, header[1].to_sym => $2, header[2].to_sym => $3, header[3].to_sym => $4 }
    end
  end
end

users_filtered = Array.new

users.each do |user|
  if user[:enabled] = 'True' and not blacklist.include?(user[:email]) and user[:email] =~ /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
    kuser = `keystone \
                    --os-username #{options[:user_name]} \
                    --os-tenant-name #{options[:tenant_name]} \
                    --os-password #{options[:user_password]} \
                    --os-auth-url #{options[:auth_url]} \
                    user-get #{user[:name]}`

    if kuser =~ /^\|\s+id\s+\|\s+(.*?)\s+\|$/m
      if $1 != tenant_id
        if options[:verbose]
          puts "Added user: #{user[:name]}, email: #{user[:email]}"
        end
        users_filtered << user
      end
    end
  end
end

from_email = conf['from_email']
from_name = conf['from_name']
from_host = conf['from_host']
smtp_server = conf['smtp_server']

if options[:verbose]
  puts "Dumping configuration"
  puts "Configuration file "
  puts YAML::dump(conf)
  puts YAML::dump(options)
end

if !options[:dry]

  begin
    Net::SMTP.start(smtp_server, 25, from_host) do |smtp|
      users_filtered.each do |user|
        if options[:verbose]
          puts "Sending email to #{user[:name]} <#{user[:email]}>"
        end

msgstr =<<-MSG
From: #{from_name} <#{from_email}>
To: #{user[:name]} <#{user[:email]}>
Subject: #{options[:subject]}

#{options[:message]}
MSG

        smtp.send_message msgstr, from_email, user[:email]
        sleep(1)
      end
    end
  rescue => ex
    puts "Caught exception #{ex}, ignoring"
  end

end
exit
