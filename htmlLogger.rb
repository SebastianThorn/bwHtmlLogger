#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This is a simple script that turn BroadWorks log-files into html-files.
# Please send me a note if you like this and would like that i keep develop it.
#
# Written by Sebastian Thörn
# Using emacs

colors = ['FFFF00','66FF00', '9900FF', 'FF0000', '0000FF', '660000']
# change color after what you feel like having, and add more colors if you have more then 6 hosts that will bounce SIP-messages.

knownIp = {'<address to ns01>'=>'netserv01', '<address to ns02>'=>'netserv02'}
# replace and add your ip-addresses here to get their name instead of ip. (opinial)


def find(inF, start, pattern)
  for i in Range.new(start,inF.length-1)
    if inF[i] =~ pattern
      return i-1
    end
  end
end

inName = ARGV[0]
outName = ARGV[1]

unless File.exists? inName
  puts "the indatafile does not exist"
  exit
end

if File.exists? outName
  print "the outdatafile does alreade exist, would you like to overwrite [y/N]? "
  a = STDIN.gets
  unless a =~ /y/i
    exit
  end
  puts "will overwrite current outdatafile"
end

inFile = File.open(inName)
inRows = Array.new
inFile.each {|line| inRows.push line}
inFile.close

puts "indatafile has #{inRows.length} lines of log."

inLength = inRows.length

filtered = Array.new

for i in Range.new(0,inLength-1)
  if inRows[i].include? " | Sip | "
    mark1 = i
    i += 1
    mark2 = find(inRows, i, /^[0-9]{4}\.[0-9]{2}\.[0-9]{2} /)
    unless inRows[mark1+2] =~ /^\s\$ new CHSS/
      space = 0
      while inRows[mark2-space] =~ /^\s$/
        space +=1
      end
      filtered.push inRows[mark1..mark2-space]
    end
  end
  i += 1
end

puts "found #{filtered.length} SIP-messages"

hosts = filtered.map { |packet| packet[2].scan(/(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)/) }
hosts.uniq!

puts "found #{hosts.length} hosts"
puts hosts

puts "starting to generate html"

html = File.new(outName, 'w+')
html.puts "<html><body>"
html.puts "<table border='1'>"
html.puts "<tr>"

i = 0
for host in hosts
  if knownIp.include? host[0][0]
    html.puts "<td bgcolor=#{colors[i]}>#{knownIp[host[0][0]]}</td>"
  else
    html.puts "<td bgcolor=#{colors[i]}>#{host}</td>"
  end
  i+=1
end
html.puts "<td bgcolor=FFFFFF>BroadWorks</td>"
html.puts "</tr>"

for packet in filtered
  head = packet[2..3]
  html.puts "<tr>"
  i = 0
  found = false
  for host in hosts
    if head[0].include? host[0][0]
      sipMsg = ""
      if head[1] =~ /^SIP\/2\.0/
        sipMsg = head[1].scan(/^SIP\/2\.0(.*)$/)
      else
        sipMsg = head[1].scan(/(^[A-Z]*.*)\@.*/)
      end
      html.puts "<td bgcolor=#FFFFFF>#{sipMsg}</td>"
      found = true
    else
      if found
        html.puts "<td bgcolor=#{colors[i]}></td>"
      else
        html.puts "<td bgcolor=#FFFFFF></td>"
      end
    end
    unless found
      i += 1
    end
  end
  if head[0].include? 'OUT'
    html.puts "<td bgcolor=#FFFFFF><- OUT</td>"
  elsif head[0].include? 'IN'
    html.puts "<td bgcolor=#FFFFFF>-> IN</td>"
  end
  html.puts "</tr>"
end

html.puts "</table>"
html.puts "</body></html>"
html.close()

puts "\n\nscript ended ok"
