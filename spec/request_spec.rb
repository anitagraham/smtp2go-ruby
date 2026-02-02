require 'spec_helper'

describe Smtp2go::Smtp2goClient do
  before :all do
    @smtp2go_client = get_client
  end

  subject { @smtp2go_client }
  it { should respond_to :send }

  it 'has a version number' do
    expect(Smtp2go::VERSION).not_to be nil
  end

  it 'performs a successful send' do
    VCR.use_cassette('successful_send') do
      response = @smtp2go_client.send(**PAYLOAD)
      expect(response.success?).to be true
    end
  end

  it 'performs a failed send' do
    VCR.use_cassette('failed_send') do
      @smtp2go_client.send(**PAYLOAD)
    end
  end

  describe 'An api key must be provided when the client is initialized' do
    context 'without an api key' do
      it 'with neither API key environment variable nor api_key option at initialization' do
        ENV['SMTP2GO_API_KEY'] = nil
        expect(ENV['SMTP2GO_API_KEY']).to be_nil
        expect { Smtp2go::Smtp2goClient.new }.to raise_error(Smtp2go::Smtp2goAPIKeyException)
      end
    end

    context 'with an api key provided' do
      it 'succeeds with an api key an environment variable' do
        ENV['SMTP2GO_API_KEY'] = 'my api key'
        expect { Smtp2go::Smtp2goClient.new }.not_to raise_error
      end

      it 'succeeds with an api key as a keyword argument to new' do
        ENV['SMTP2GO_API_KEY'] = nil
        expect { Smtp2go::Smtp2goClient.new(api_key: 'my api key') }.not_to raise_error
      end
    end
  end

  it 'attaches version headers to requests' do
    expect(HTTParty).to receive(:post).with(
      any_args, hash_including(headers: hash_including(Smtp2go::HEADERS) )
    ).and_return get_response_object
    VCR.use_cassette('successful_send') do
      @smtp2go_client.send(**PAYLOAD)
    end
  end

  it 'attaches Content-Type to requests' do
    # Check headers contain Content-Type:
    expect(Smtp2go::HEADERS).to include(
       'Content-Type' => Smtp2go::HEADERS['Content-Type'])

    expect(HTTParty).to receive(:post).with(
      any_args, hash_including(headers: hash_including(Smtp2go::HEADERS))
    ).and_return get_response_object
    VCR.use_cassette('successful_send') do
      @smtp2go_client.send(**PAYLOAD)
    end
  end

  it 'raises an exception if not provided one of html, text or template in the call to send' do
    VCR.use_cassette('successful_send') do
      payload = PAYLOAD.clone
      payload[:html] = nil
      payload[:text] = nil
      payload[:template] = nil
      expect { @smtp2go_client.send(**payload) }.to raise_error(
                                                    Smtp2go::Smtp2goParameterException
                                                  )
    end
  end

  it 'raises an exception if template does not include id and data members' do
    VCR.use_cassette('successful_send') do
      payload = PAYLOAD.clone
      payload[:html] = nil
      payload[:text] = nil
      payload[:template] = {"fred": "nurk"}
      expect { @smtp2go_client.send(**payload) }.to raise_error(
                                                      Smtp2go::Smtp2goTemplateException
                                                    )
    end
  end
  it 'sends an email if html is not passed to send' do
    VCR.use_cassette('successful_send') do
      payload = PAYLOAD.clone
      payload[:html] = nil
      expect(payload[:html]).to be_nil
      response = @smtp2go_client.send(**PAYLOAD)
      expect(response.success?).to be true
    end
  end

  it 'sends an email if text is not passed to send' do
    VCR.use_cassette('successful_send') do
      payload = PAYLOAD.clone
      payload[:text] = nil
      expect(payload[:text]).to be_nil
      response = @smtp2go_client.send(**PAYLOAD)
      expect(response.success?).to be true
    end
  end

  it 'sends an email if template is not passed to send' do
    VCR.use_cassette('successful_send') do
      payload = PAYLOAD.clone
      payload[:template] = nil
      expect(payload[:template]).to be_nil
      response = @smtp2go_client.send(**PAYLOAD)
      expect(response.success?).to be true
    end
  end
end
