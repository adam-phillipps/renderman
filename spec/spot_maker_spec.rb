require 'dotenv'
Dotenv.load
require 'aws-sdk'
require 'byebug'

class SpotMaker
  def initialize
  	configure_aws
  	run_program
  end

  def configure_aws
  	Aws.config.update({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
		})
  end

  def run_program
  	get_backlog_messages
  end

  def get_backlog_messages
  	backlog_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/backlog'
  	poller = Aws::SQS::QueuePoller.new(backlog_queue_url)
  	message_arr = []
  	poller.poll(visibility_timeout: 0, skip_delete: true) do |msg|
  	  byebug
  	  message_arr << msg
  	end
  	message_arr
  end
end

SpotMaker.new