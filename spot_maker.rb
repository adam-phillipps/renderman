require 'dotenv'
Dotenv.load
require 'aws-sdk'
require "#{File.dirname(__FILE__)}/spot_helper"
require 'byebug'

class SpotMaker
	include SpotHelper

  def initialize
  	@units_of_work_in_backlog, @units_of_work_in_wip = 0,0
  	@backlog_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/backlog'
  	@wip_queue_url = 'https://sqs.us-west-2.amazonaws.com/828660616807/wip'
  	@threshold_ratio = 1.0/2.0
  	@instance_type = 'm4.large'
  	@product_description = 'Windows'
  	@sqs = SpotHelper.sqs
  	#@sqs = SpotHelper.sqs_client
  	@ec2 = SpotHelper.ec2_client
  	byebug
  	run_program
  end

  def run_program
  	loop do
  		ratio = ratio_of_backlog_to_wip
  		ten_jobs_per_slave = (SpotHelper.number_of_jobs_in(@backlog_queue_url).to_f / 10.0).floor
  		start_slaves(instance_count: ten_jobs_per_slave) if ratio >= @threshold_ratio
  		sleep 30
  	end
  end

  def ratio_of_backlog_to_wip
  	wip = SpotHelper.number_of_jobs_in(@wip_queue_url)
  	wip = wip == 0.0 ? 0.01 : wip # avoids devision by 0 exception
  	SpotHelper.number_of_jobs_in(@backlog_queue_url) / wip
  end

  def best_price_and_zone_for(options={})
  	spot_prices = []
  	SpotHelper.all_zones.each do |az|
      spot_prices << SpotHelper.ec2_client.describe_spot_price_history(
      start_time: (Time.now - 86400).iso8601.to_s,
      instance_types: [options[:instance_types]],
      product_descriptions: [options[:product_description]],
      availability_zone: az)
    end
    best_match = map_for_required_options(spot_prices)
    best_match[:spot_price] = SpotHelper.add_buffer_to_price(best_match[:spot_price])
    best_match
  end

  def map_for_required_options(spot_prices)
  	byebug
  	spot_prices.each.map(&:spot_price_history).flatten.
      map{ |sph| {spot_price: sph.spot_price, availability_zone: sph.availability_zone, instance_type: sph.instance_type} }.
        min_by {|sp| sp[:price]}
  end

  def start_slaves(options={})
  	byebug
  	options.merge!(best_price_and_zone_for(
  		instance_types: @instance_type, product_description: @product_description))
  	count = options[:instance_count]
  	if count > 20 
  		((count/20).floor).times do# find out if this is how many should be started
				request_spot_instances(2,options)# use 20 for real life.  2 is for testing
		  end
		else
		 	request_spot_instances(count.ceil,options)
	  end
  end

  def request_spot_instances(count, options)
  	@ec2.request_spot_instances(
		  		spot_price: options[:spot_price],
		  		instance_count: count,
		  		launch_specification: {
		  			image_id: 'ami-9384f7a3', # using RenderSlave ami for testing
		  			instance_type: options[:instance_type],
		  			placement: {availability_zone: options[:availability_zone]}})#,
		  			#block_device_mappings: get the block device mappings for this ami
  end
end
SpotMaker.new