require 'sinatra'
require 'json'
require_relative 'tripping'

configure do 
	file = File.read('test_json.json')
	data = JSON.parse(file)

	set :prop, Tripping::Property.new(data: data)
end

get '/test' do
	return settings.prop.start_date
end