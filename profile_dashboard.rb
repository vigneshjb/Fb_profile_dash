require 'net/http'
require 'json'
# require 'debugger'
require 'uri'

base_url = "https://graph.facebook.com/"
field_albums = "name"
time_field_likes_comments = "updated_time,comments.limit(1).summary(true),likes.limit(1).summary(true)"
picture = "picture,"
message = "message,"

access_token = ""
user_id = "me"

def make_http_request(url)
	begin
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		request = Net::HTTP::Get.new(uri.request_uri)
		response = http.request(request)
	rescue => e
		puts "Error: makig an HTTP request :"+e.to_s
	end
	JSON.parse(response.body, :symbolize_names=>true) || {}
end

def fetch_paginated_data(url)
	result_set = make_http_request(url)
	while result_set[:paging] && result_set[:paging][:next]
		to_append = make_http_request(result_set[:paging][:next])
		to_append[:data].each{|post| result_set[:data].push(post)}
		result_set.delete(:paging)
		result_set[:paging] = to_append[:paging]
	end
	result_set
end

# FETCH ALL ALBUM IDS 
album_id=0
request_album_list_url = base_url+user_id+"/albums"+"?fields="+field_albums+"&access_token="+access_token
puts "Making a HTTP request to "+ request_album_list_url
json_response = fetch_paginated_data(request_album_list_url)
json_response[:data].each{|item| album_id = item[:id] if item[:name]=="Profile Pictures" }
puts "album id is: "+album_id

# # FETCH IMAGES, LIKES and COMMENTS
profile_photos_array = []
request_images_likes_comments_url = base_url+album_id+"/photos"+"?fields="+picture+time_field_likes_comments+"&access_token="+access_token
puts "making request to "+request_images_likes_comments_url
json_response = fetch_paginated_data(request_images_likes_comments_url)
json_response[:data].each{|node| profile_photos_array.push({:picture_url => node[:picture], 
	:upload_time => node[:updated_time], :total_likes => node[:likes][:summary][:total_count], 
	:total_comments => node[:comments][:summary][:total_count] }) }

statuses_array = []
request_status_url = base_url+user_id+"/statuses"+"?fields="+message+time_field_likes_comments+"&access_token="+access_token
puts "making request to "+request_status_url
json_response = fetch_paginated_data(request_status_url)
json_response[:data].each{|node| statuses_array.push({:message => node[:message], 
	:upload_time => node[:updated_time], :total_likes => node[:likes]?node[:likes][:summary][:total_count]:0, 
	:total_comments => node[:comments]?node[:comments][:summary][:total_count]:0 }) unless node[:message].nil?}

puts "profile_photos_array = #{profile_photos_array.length} and statuses_array = #{statuses_array.length}"
