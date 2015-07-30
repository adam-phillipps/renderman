require 'dotenv'
DotEnv.load
require 'aws-sdk'
require 'byebug'

class RenderSlave
	def initialize
		@poller = SpotHelper.sqs_poller
		run_program
	end

	def run_program
		@poller.poll(visibility_timeout: 180) do |msg|
			# parse message json for job info
			# run job(Time.now)
			`job_that_works_in_linux` # find a way to make it work for windows
		end

		def run_job#(start_time)
			`job_that_works_in_linux` # find a way to make it work for windows
#			time_left = start_time.to_i
#			until 5 >= time_left do
#     	  time_left = Time.now - start_time
#      	#running job code 
#      	# if base case is met, 
#      end
#      @poller.change_message_visibility_timeout(msg, (Time.at(start_time) + 60))
		end
	end
end

RenderSlave.new