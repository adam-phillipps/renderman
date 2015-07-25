require 'spec_helper'
require_relative '../spot_maker'

describe SpotMaker do
  it 'should configure Aws' do
  	spot_maker = SpotMaker.new
  	puts spot_maker
  	spot_maker[:credentials].should be_an_instance_of Aws::Credentials
  end
end