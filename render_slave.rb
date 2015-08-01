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
#   @boot_time = get_boot_time
		@timeout = 120#3300 # 55 minutes
		@initial_timeout = @timeout
		@backlog_message = nil
    @wip_message = nil

    poll
	end

	def get_instance_id
		info = nil
		Open3.poponen3('curl http://169.254.169.254/latest/meta-data/') do |stdin, stdout, stderr|
			info = stdout
		end
		info['instance-id']
	end

	def get_boot_time
		@ec2_client.describe_spot_instance_requests({
			spot_instance_request_ids: [@instance_id]
			})[0].create_time
	end

  def poll
    @poller.poll(visibility_timeout: @timeout, wait_time_seconds: @timeout) do |msg|     
      @backlog_message = msg
      @wip_message = nil 
      run_job # run_job deletes message after it's finished
      if viable?
        continue_to_poll
      else
        if should_stop?#@ec2_client.stop_instances({instance_id: [@instance_id]}) if should_stop?
          puts 'stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self stopping self' 
        end
      end
    end
  end

	def run_job
		send_message_to_wip
		add_time_to_message_if_needed
		# run the job and monitor the time so it can add more if it needs it
		@sqs_client.delete_message({
			queue_url: @backlog_queue_url,
			receipt_handle: @backlog_message.receipt_handle})
    @sqs_client.delete_message({
      queue_url: @wip_queue_url,
      receipt_handle: get_wip_message_handle})
		@backlog_message = nil
    @wip_message = nil
	end

  def get_wip_message_handle
    @sqs_client.receive_message({
      queue_url: @wip_queue_url,
      message_attribute_names: [@backlog_message.message_attributes],
      max_number_of_messages: 1,
      visibility_timeout: 5,
      wait_time_seconds: 1})[0].first.receipt_handle
  end

  def timeout
    @timeout = Time.now.to_i - @boot_time
  end

	def job_still_running?
		true
	end

	def should_stop?
		if (SpotHelper.ratio_of_backlog_to_wip <= 10)
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
		if (((Time.now.to_i - @boot_time) >= @timeout) || (job_still_running?))
			SpotHelper.sqs_client.change_message_visibility({
				queue_url: @backlog_queue_url,
				receipt_handle: @backlog_message.receipt_handle,
				visibility_timeout: (@initial_timeout += @timeout)})
		end
	end

	def viable?
		SpotHelper.ratio_of_backlog_to_wip >= 10 ? true : false
	end

	def send_message_to_wip	
		@sqs_client.send_message({
		  queue_url: @wip_queue_url,
		  message_body: @backlog_message.body,
		  message_attributes: @backlog_message.message_attributes})
	end
end

RenderSlave.new