require 'dotenv'
Dotenv.load
require 'aws-sdk'
require "#{File.dirname(__FILE__)}/spot_helper"
require 'byebug'

class RenderSlave
	def initialize
		@boot_time = Time.now.to_i # seconds from epoch
		@backlog_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/backlog'
		@wip_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/wip'
		@sqs_client = SpotHelper.sqs_client
		@ec2_client = SpotHelper.ec2_client
		@poller = SpotHelper.sqs_poller(@backlog_queue_url)
#		@instance_id = SpotHelper.get_self_instance_id
		@timeout = 120#3300 # 55 minutes
		@initial_timeout = @timeout
		@message = nil

		@poller.poll(visibility_timeout: @timeout) do |msg|			
			@message = msg 
			run_job # run_job deletes message after it's finished
			if viable?
				continue_to_poll
			else
				puts 'asdfasdfasdfasdfasdfasdf' if should_stop?#@ec2_client.stop_instances({instance_id: [@instance_id]}) if should_stop?
			end
		end
	end

	def run_job
		send_message_to_wip
		add_time_to_message_if_needed
		# run the job and monitor the time so it can add more if it needs it
		@sqs_client.delete_message({
			queue_url: @backlog_queue_url,
			receipt_handle: @message.receipt_handle})
		@message = nil
	end

	def job_still_running?
		true
	end

	def should_stop?
		if (ratio <= 10)
			if ((@boot_time - Time.now.to_i) >= @timeout)
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
	end

	def add_time_to_message_if_needed
		if (((Time.now.to_i - @boot_time) >= @timeout) && (job_still_running?))
			SpotHelper.sqs_client.change_message_visibility({
				queue_url: @backlog_queue_url,
				receipt_handle: @message.receipt_handle,
				visibility_timeout: (@initial_timeout += @timeout)})
		end
	end

	def viable?
		ratio >= 10 ? true : false
	end

	def ratio
		SpotHelper.ratio_of_backlog_to_wip
	end

	def send_message_to_wip	
		if !@message.message_attributes.nil?
			attributes = {
			  "String" => {
		      string_value: @message.message_attributes['string_value'],
		      string_list_values: ["String"],
		      data_type: "String"}}
		else
			attributes = {}
		end
		@sqs_client.send_message({
		  queue_url: @wip_queue_url,
		  message_body: @message.body,
		  message_attributes: attributes})
	end
end

RenderSlave.new