#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# This is a simple script that turn BroadWorks log-files into html-files.
# Please send me a note if you like this and would like that i keep develop it.
#
# Written by Sebastian Thörn
# Using emacs

colors = ['FFFF00','66FF00', '9900FF', 'FF0000', '0000FF', '660000']
# change color after what you feel like having
# add more colors if you have more then 6 hosts that will bounce SIP-messages

knownIp = {'<address to ns01>'=>'netserv01', '<address to ns02>'=>'netserv02', '<address to sbc>'=>'sbc', '<address to some trunk>'=>'MX-one'}
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

body = "<body>\n"
body += "<table border='1'>\n"
body += "<tr>"

header = "<head>\n"

popup = "<td bgcolor=#FFFFFF><a onmouseover='this.style.cursor=\"pointer\" ' onfocus='this.blur();' onclick=\"document.getElementById('msg<ID>').style.display = 'block' \" >\n
      <span style=\"text-decoration: underline;\"><WAY></span>
    </a>
    <div id='msg<ID>' style='display: none; position: absolute; left: 50px; top: <TOP>px; border: solid black 1px; padding: 10px; background-color: rgb(255,255,225); text-align: justify; font-size: 12px; float:left;'>\n
<PACKET>}
    <br />
    <div style='text-align: right;'><a onmouseover='this.style.cursor=\"pointer\" ' style='font-size: 12px;' onfocus='this.blur();' onclick=\"document.getElementById('msg<ID>').style.display = 'none' \" >
      <span style=\"text-decoration: underline;\">
Close
      </span></a></div></div></td>"

i = 0
for host in hosts
  if knownIp.include? host[0][0]
    body += "<th bgcolor=#{colors[i]}>#{knownIp[host[0][0]]}</th>\n"
  else
    body += "<th bgcolor=#{colors[i]}>#{host}</th>\n"
  end
  i+=1
end
body += "<th bgcolor=FFFFFF>BroadWorks</th>\n"
body += "</tr>\n"

jsname = 1
for packet in filtered
  head = packet[2..3]
  body += "<tr>\n"
  i = 0
  found = false
  for host in hosts
    if head[0].include? host[0][0]
      sipMsg = ""
      if head[1] =~ /^SIP\/2\.0/
        sipMsg = head[1].scan(/^SIP\/2\.0 (.*)$/)
      elsif head[1] =~ /^[A-Z]*.*\@.*/
        sipMsg = head[1].scan(/(^[A-Z]*.*)\@.*/)
      else
        sipMsg = head[1].scan(/(^[A-Z]*) .*/)
      end
      body += "<td bgcolor=#FFFFFF>#{sipMsg}</td>\n"
      found = true
    else
      if found
        body += "<td bgcolor=#{colors[i]}></td>\n"
      else
        body += "<td bgcolor=#FFFFFF></td>\n"
      end
    end
    unless found
      i += 1
    end
  end
  if head[0].include? 'OUT'
    body += popup.gsub('PACKET',packet.join('<br />')).gsub('<ID>', jsname.to_s).gsub('<WAY>','Packet out').gsub('<TOP>', (24*jsname).to_s)
  elsif head[0].include? 'IN'
    body += popup.gsub('PACKET',packet.join('<br />')).gsub('<ID>', jsname.to_s).gsub('<WAY>','Packet in').gsub('<TOP>', (24*jsname).to_s)
  end
  body += "</tr>\n"
  jsname += 1
end
body += "</table>\n"


body += "</body>\n"
header += "</head>\n"

html = File.new(outName, 'w+')
html.puts "<html>"
html.puts header
html.puts body
html.puts "</html>"
html.close()

puts "\n\nscript ended ok"
