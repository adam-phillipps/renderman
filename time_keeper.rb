class TimeKeeper
	def initialize
		@start_time = Time.now
		until no_time_left?
			sleep 10
		end
		puts false
	end

	def no_time_left?
		(Time.now - @start_time) <= 3300
	end
end

TimeKeeper.new