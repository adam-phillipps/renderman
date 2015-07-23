require 'spec_helper'

require_relative '../spot_maker'

describe SpotMaker do
  it 'should be valid' do
  	expect(subject).to be_kind_of SpotMaker
  end

  it 'should configure Aws' do
  	expect(subject.configure_aws[:credentials]).to be_kind_of Aws::Credentials
  end

  it 'should get messages from backlog sqs queue' do
  	#expect(subject.get_backlog_messages).to 
  end
end