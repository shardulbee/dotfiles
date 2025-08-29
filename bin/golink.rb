#!/usr/bin/env ruby

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title golinks
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔗
# @raycast.argument1 { "type": "text", "placeholder": "path" }

# Documentation:
# @raycast.description Navigate to a golink
# @raycast.author turbochardo
# @raycast.authorURL https://raycast.com/turbochardo

require 'shellwords'

processed_input = ARGV[0].split(' ').join('/')
url = "https://go.tail8779.ts.net/#{processed_input}"

system("open #{url.shellescape}")
print("Opened go/#{processed_input}")
