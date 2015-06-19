require 'date'

def run!
	require 'json'
	require 'optparse'
	# Read file and interpret as json
	options = {file: 'test_json.json'}
	OptionParser.new do |opts|
	  opts.banner = "Usage: ruby tripping.rb [options]"

	  opts.on("-f", "--file", "Path to seed json file") do |v|
	    options[:file] = v
	  end

	  opts.on("-r","--range x,y", Array, "Dates between which stay is requested") do |list|
        options[:range] = list
      end
	end.parse!

	file = File.read(options[:file])
	data = JSON.parse(file)


	rtrn_val = {}
	prop = Tripping::Property.new(data: data)

	if options[:range].nil?
		rtrn_val["available_date_ranges"] = prop.range
	else

		#Validate values
			day1 = Date.parse(options[:range][0])
			day2 = Date.parse(options[:range][1])

			stay_len = (day2-day1).to_i

		#Invalid if day1 comes after day2
			raise("start_day after end_day") if stay_len <=0

		#check if stay satisfies minstay
		satisfy,minstay =prop.satisfy_minstay?(start_day: day1,stay_length: stay_len)
		if !satisfy
			rtrn_val["status"] = "error"
			rtrn_val["description"] = "minstay not satisfied"
			rtrn_val["minstay"] = minstay
		end

		if prop.is_avail?(start_day: day1, end_day: day2)
			#make sure that the stay satisfies minstay on checkin
			if !satisfy
				rtrn_val["status"] = "error"
				rtrn_val["description"] = "minstay not satisfied"
				rtrn_val["minstay"] = minstay
			else
				rtrn_val[:status] = "Available"
				rtrn_val[:price] = prop.cost(start_day: day1, end_day: day2)
			end
		else
			rtrn_val[:status] = "Unavailable" 
		end

	end

	puts JSON.pretty_generate(rtrn_val)

end


module Tripping
	class Property
		attr_reader :range,:start_date,:minstay,:avail
		def initialize(data:)
				@start_date = Date.parse(data["start_date"])
				@minstay = data['minstay'].split(',').map{|x| x.to_i}
				@price = data['price'].split(',').map{|x| x.to_i}

				@avail = availability_process(avail: data['availability'])


				@range = get_range()
		end

		def is_avail?(start_day: nil, end_day: nil,start_in: nil,end_in: nil)
			raise "start_day or start_in required" if start_day == nil and start_in == nil
			raise 'end_day or end_in required' if end_day ==nil and end_in == nil
			start_in ||= (start_day - @start_date).to_i
			end_in   ||= (end_day - @start_date).to_i

			
			subset = @avail[start_in..end_in]
			if subset.include?(0)
				return false
			else
				return true
			end
		end

		def satisfy_minstay?(start_day:, stay_length:)
			start_in = (start_day - @start_date).to_i
			if @minstay[start_in] <= stay_length
				return true,@minstay[start_in]
			else
				return false,@minstay[start_in]
			end
		end

		def cost(start_day: nil, end_day: nil,start_in: nil,end_in: nil)
			raise "start_day or start_in required" if start_day == nil and start_in == nil
			raise 'end_day or end_in required' if end_day ==nil and end_in == nil

			start_in ||= (start_day - @start_date).to_i
			end_in   ||= (end_day - @start_date).to_i

			cost = @price[start_in..end_in].reduce(:+)
			return cost
		end


		private
		#given an index, return the date as a string
		def get_date(index:)
			return (@start_date + index).to_s
		end

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

		def get_range()
			return @range unless @range.nil?
			#find consecutive days
			last = false
			temp = []
			store = []
			@avail.each_with_index do |val,index|
				if last == true
					if val ==1
						# next
						if stay_min?(index: index)
							next
						else
							last = false
							temp << get_date(index: index-1)
							store << Array.new(temp)
							temp = []
						end
					else
						last = false
						temp << get_date(index: index-1)
						store << Array.new(temp)
						temp = []
					end
				else
					if val == 1
						if stay_min?(index:index)
							last = true
							temp = [get_date(index:index)]
						end
					else
						last = false
						next
					end
				end
			end
			if last == true
				temp << get_date(index: @avail.length-1)
				store << Array.new(temp)
				temp = []
			end
			return store

		end

		#stay_min finds if a property is available for the minstay
		#from the given date (in the form of an index)
		def stay_min?(index:)
			return false if minstay[index].nil?
			return self.is_avail?(start_in: index,end_in: index+@minstay[index])
		end

	end

end

run! if __FILE__==$0

