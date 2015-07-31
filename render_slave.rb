require 'dotenv'
Dotenv.load
require 'aws-sdk'
require 'spot_helper'
require 'byebug'

class RenderSlave
	def initialize
		@poller = SpotHelper.sqs_poller
		@instance_id = SpotHelper.get_self_instance_id
		@backlog_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/backlog'

		Open3.popen3('ruby time_keeper.rb') do |stdin, stdout, stderr|
			until (stdout.gets == false) do
				@poller.poll(visibility_timeout: 180) do |msg|
#         parse message json for job info					
#					Open3.popen3(rendering job) do |stdin, stdout, stderr|
#					or
#					`rendering job`
			end
			if job_still_running?
#       do nothing?
			else
				SpotHelper.number_of_jobs_in(@backlog_queue_url)
#				if no messages, let time run out
#				else request ratio of backlog to wip
#					if ratio is big enough, request more time
#					else let time run out
#			end
		end
	end

	def job_still_running?
	end
end

RenderSlave.new