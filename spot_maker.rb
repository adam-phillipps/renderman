require 'dotenv'
Dotenv.load
require 'aws-sdk'

class SpotMaker
  def initialize
  	configure_aws
  end

  def configure_aws
  	Aws.config.update({
      region: ENV['AWS_REGION'],
  	  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
	})
  end
end

SpotMaker.new