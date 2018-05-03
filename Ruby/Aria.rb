require 'uri'
require 'net/http'
require 'colorize'

url = URI("")  ### add api key URI

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true


request = Net::HTTP::Get.new(url)

response = http.request(request)

x = "error_code: Aria-assigned error identifier. 0 indicates no error."
y = "error_msg: Description of any error that occurred. OK if there was no error."
z = "version: The current system version."


while true
  puts x.blue
  puts y.blue
  puts z.blue
  puts response.read_body.green
  sleep 30
end
