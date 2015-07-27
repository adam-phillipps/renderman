module SpotHelper
	def create_sqs_client
  	Aws::SQS::Client.new({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
  end

  def create_ec2_client
  	Aws::EC2::Client.new({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(
  	  	ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])})
  end

	def add_buffer_to_price(price)
  	price.to_f + (price.to_f*0.2).round(3).to_s
  end
	
	def all_zones
  	@zones ||= @ec2.describe_availability_zones.
    	availability_zones.map(&:zone_name)
  end
end