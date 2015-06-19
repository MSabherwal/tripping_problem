require 'json'
require 'date'

# Read file and interpret as json
file = File.read('test_json.json')
data = JSON.parse(file)

# @avail = data['availability']
# puts @avail.length

module Tripping
	class Property
		def initialize(data:)
				@start_date = Date.parse(data["start_date"])
				@minstay = data['minstay'].split(',').map{|x| x.to_i}
				@price = data['price'].split(',').map{|x| x.to_i}

				@avail = availability_process(avail: data['availability'])
		end

		def is_avail?(start_day: nil, end_day: nil,start_in: nil,end_in: nil)
			raise "start_day or start_in required" if start_day == nil and start_in == nil
			raise 'end_day or end_in required' if end_day ==nil and end_in == nil
			start_in ||= (Date.parse(start_day) - @start_date).to_i
			end_in   ||= (Date.parse(end_day) - @start_date).to_i

			
			subset = @avail[start_in..end_in]
			if subset.include?(0)
				return false
			else
				return true
			end
		end

		private

		def availability_process(avail:)
			holder = []
			avail.each_char do |val|
				if val == 'N'
					holder << 0
				elsif val == 'Y'
					holder << 1
				else
					raise('Unknown value in availability string')
				end
			end
			return holder
		end

	end

end



prop = Tripping::Property.new(data: data)



# @minstay = data['minstay'].split(',').map{|x| x.to_i}
# # puts @minstay.inspect

# @price = data['price'].split(',').map{|x| x.to_i}
# puts @price.length


# puts @minstay.length/@avail.length.to_f
# puts @price.length/@minstay.length

# puts @price.class
# puts @minstay.class
# puts @avail.class
