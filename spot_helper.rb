module SpotHelper
	def SpotHelper.sqs_client
  	Aws::SQS::Client.new({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
  end

  def SpotHelper.ec2_client
  	Aws::EC2::Client.new({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
  end

	def SpotHelper.add_buffer_to_price(price)
  	price.to_f + (price.to_f*0.2).round(3).to_s
  end
	
	def SpotHelper.all_zones
		byebug
  	self.ec2_client.describe_availability_zones.
    	availability_zones.map(&:zone_name)
  end
end