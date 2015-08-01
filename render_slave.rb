require 'dotenv'
Dotenv.load
require 'aws-sdk'
require 'spot_helper'
require 'byebug'

class RenderSlave
	def initialize
		@boot_time = Time.now.to_i # seconds from epoch
		@sqs_client = SpotHelper.sqs_client
		@ec2_client = SpotHelper.ec2_client
		@poller = SpotHelper.sqs_poller
		@instance_id = SpotHelper.get_self_instance_id
		@backlog_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/backlog'
		@initial_timeout = 3480 # 58 minutes
		@message_receipt_handle = nil

		@poller.poll(visibility_timeout: @initial_timeout) do |msg|
			unless msg.receipt_handle.nil?
				@message_receipt_handle = msg.receipt_handle 
				run_job # run_job deletes message after it's finished
				continue_to_poll if viable?
			end
			@ec2_client.stop_instances({[instance_id: @instance_id]}) if should_stop?
		end
	end

	def run_job
		add_time_to_message_if_needed

		@message_receipt_handle = nil
	end

	def should_stop?
		if (ratio <= 10)
			if ((@boot_time - Time.now.to_i) <= 120)
				true
			else
				continue_to_poll
			end
		else
			continue_to_poll
		end
#    should stop if there's no time and there's no work
	end

	def continue_to_poll
		unless @message_receipt_handle.nil?
			@sqs_client.delete_message({
				queue_url: @backlog_queue_url,
				receipt_handle: @message_receipt_handle})
		end
	end

	def add_time_to_message_if_needed
		if (((@boot_time - Time.now.to_i) <= 300) && (job_still_running?))
			SpotHelper.sqs_client.change_message_visibility({
				queue_url: @backlog_queue_url,
				receipt_handle: @message_receipt_handle,
				visibility_timeout: (@initial_timeout += 3480)})
		end
	end

	def viable?
		ratio >= 10 ? true : false
	end

	def ratio
		SpotHelper.ratio_of_backlog_to_wip
	end
end

RenderSlave.new