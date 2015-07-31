module SpotHelper
	def SpotHelper.sqs_client
  	Aws::SQS::Client.new({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
  end

  def SpotHelper.sqs_poller(url)
  	Aws::SQS::QueuePoller.new(url)
  end

  def SpotHelper.ec2_client
  	Aws::EC2::Client.new({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
  end

	def SpotHelper.add_buffer_to_price(price)
		byebug
		new_price = price.to_f
  	((new_price + (new_price * 0.2)).round(3)).to_s
  end
	
	def SpotHelper.all_zones
  	self.ec2_client.describe_availability_zones.
    	availability_zones.map(&:zone_name)
  end

  def SpotHelper.number_of_jobs_in(url)
  	@sqs.get_queue_attributes(
  		queue_url: url,
  		attribute_names: ['ApproximateNumberOfMessages']).
  			attributes['ApproximateNumberOfMessages'].to_f
  end

  def SpotHelper.get_self_instance_id
    `curl http://169.254.169.254/latest/meta-data/instance-id`
  end
end