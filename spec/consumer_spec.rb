require_relative 'spec_helper'

describe Consumer do
  let(:queue) { instance_double('Bunny::Queue', bind: nil, subscribe: nil) }
  let(:channel) { instance_double('Bunny::Channel', queue: queue, prefetch: nil, topic: nil) }
  let(:rabbitmq_connecton) { instance_double("Bunny::Session", start: nil, create_channel: channel) }

  before do
    stub_environment_variables!
    allow(Bunny).to receive(:new).and_return(rabbitmq_connecton)
  end

  describe "running the consumer" do

    class Processor
      ROUTING_KEY = "*.major"
    end

    it "binds the queue to a custom routing key" do
      expect(queue).to receive(:bind).with(nil, { routing_key: "*.major" })

      Consumer.new(queue_name: "some-queue", exchange_name: "my-exchange", processor: Processor.new).run
    end

    it "calls the heartbeat processor when subscribing to messages" do
      expect(queue).to receive(:subscribe).and_yield(:delivery_info1, :headers1, "message1_payload")
      expect(Message).to receive(:new).with("message1_payload", :headers1, :delivery_info1)
      expect_any_instance_of(HeartbeatProcessor).to receive(:process)

      Consumer.new(queue_name: "some-queue", exchange_name: "my-exchange", processor: Processor.new).run
    end
  end
end
