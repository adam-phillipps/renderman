require 'dotenv'
Dotenv.load
require 'aws-sdk'
require "#{File.dirname(__FILE__)}/spot_helper"
require 'byebug'

class SpotMaker
  def initialize
  	byebug
  	@units_of_work_in_backlog, @units_of_work_in_wip = 0,0
  	@backlog_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/backlog'
  	@wip_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/wip'
  	@threshold_ratio = 1.0/2.0
  	@instance_type = 'm3.large'
  	@product_description = 'windows'
  	@sqs = SpotHelper.create_sqs_client
  	@ec2 = create_ec2_client
  	run_program
  end

  def run_program
  	byebug
  	ratio = ratio_of_backlog_to_wip
  	if ratio >= @threshold_ratio
  		start_slaves
  	else
  		# do nothing
  	end
  end

  def number_of_jobs_in_backlog
  	byebug
  	@sqs.get_queue_attributes(
  		queue_url: @backlog_queue_url,
  		attribute_names: ['ApproximateNumberOfMessages']).to_f
  end

  def number_of_jobs_in_wip
  	@sqs.get_queue_attributes(
  		queue_url: @wip_queue_url,
  		attribute_names: ['ApproximateNumberOfMessages']).to_f
  end

  def ratio_of_backlog_to_wip
  	wip = number_of_jobs_in_wip
  	wip = wip.eql? 0.0 ? 0.01 : wip # avoids devision by 0 exception
  	number_of_jobs_in_backlog / wip
  end

  def best_price_and_zone_for(options={})
  	all_zones.each do |az|
      spot_prices << ec2_client.describe_spot_price_history(
      start_time: (Time.now + 36000).iso8601.to_s,
      instance_types: [options[:instance_type]],
      product_descriptions: [options[:product_description]],
      availability_zone: az)
    end
    best_match = map_for_required_options(spot_prices)
    best_match[:spot_price] = add_buffer_to_price(best_match[:spot_price])
    best_match
  end

  def map_for_required_options(spot_prices)
  	spot_prices.each.map(&:spot_price_history).flatten.
      map{ |sph| {spot_price: sph.spot_price, availability_zone: sph.availability_zone, instance_type: sph.instance_type} }.
        min_by {|sp| sp[:price]}
  end

  def start_slaves(options={})
  	options.merge!(best_price_and_zone_for(instance_types: @instance_type, product_description: @product_description))
  	@ec2.request_spot_instances(
  		spot_price: options[:spot_price],
  		instance_count: ratio_of_backlog_to_wip.ceil,
  		launch_specification: {
  			image_id: 'asdf',
  			instance_type: options[:instance_type],
  			placement: {availability_zone: options[:availability_zone]}#,
  			#block_device_mappings: get the block device mappings for this ami
  		}
  	)
  end
end

SpotMaker.new

#  def create_ec2_client
#  	Aws::EC2::Client.new({
#      region: ENV['AWS_REGION'],
#  	  credentials: Aws::Credentials.new(
#  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
#  end
#
#  def create_sqs_client
#  	Aws::SQS::Client.new({
#      region: ENV['AWS_REGION'],
#  	  credentials: Aws::Credentials.new(
#  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
#  end
#
#  def add_buffer_to_price(price)
#  	price.to_f + (price.to_f*0.2)).round(3).to_s
#  end
#
# 	def all_zones
#  	@zones ||= @ec2.describe_availability_zones.
#    	availability_zones.map(&:zone_name)
#  end
