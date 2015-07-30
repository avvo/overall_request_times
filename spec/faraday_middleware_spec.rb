require 'spec_helper'

describe OverallRequestTimes::FaradayMiddleware do
  class TestAppWithOnComplete
    attr_accessor :response_env, :do_this_before_complete

    def call(_request_env)
      self
    end

    def on_complete(&block)
      do_this_before_complete.call if do_this_before_complete
      block.call(response_env)
      self
    end
  end

  let(:app) { TestAppWithOnComplete.new }
  let(:remote_app_name) { :cats }
  let(:env) { {} }

  subject { OverallRequestTimes::FaradayMiddleware.new(app, remote_app_name) }

  it 'starts with a total of zero' do
    expect(subject.total).to eq(0)
  end

  it 'knows its name' do
    expect(subject.remote_app_name).to eq(:cats)
  end

  it 'can add some time' do
    subject.add(10)
    expect(subject.total).to eq(10)
  end

  it 'can be reset' do
    subject.add(10)
    subject.reset!
    expect(subject.total).to eq(0)
  end

  describe '#call' do
    it 'calls the app' do
      expect(app).to receive(:call).with(env).and_return(app)
      subject.call(env)
    end

    it 'records the time it takes before the call completes' do
      now = Time.now
      Timecop.travel(now)

      app.do_this_before_complete = -> {
        Timecop.travel(now + 5)
      }

      subject.call(env)

      expect(subject.total).to be_within(0.01).of(5)

      Timecop.return
    end
  end
end