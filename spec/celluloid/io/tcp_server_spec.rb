require "spec_helper"

RSpec.describe Celluloid::IO::TCPServer, library: :IO do
  context "#accept" do
    let(:payload) { "ohai" }
    let(:example_port) { assign_port }

    it "can be initialized without a host" do
      expect { Celluloid::IO::TCPServer.new(2000).close }.to_not raise_error
    end

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_tcp_server(example_port) do |subject|
          expect(within_io_actor { Celluloid::IO.evented? }).to be_truthy
        end
      end

      it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
        with_tcp_server(example_port) do |subject|
          thread = Thread.new { TCPSocket.new(example_addr, example_port) }
          peer = within_io_actor { subject.accept }
          expect(peer).to be_a Celluloid::IO::TCPSocket

          client = thread.value
          client.write payload
          expect(peer.read(payload.size)).to eq payload
        end
      end

      context "outside Celluloid::IO" do
        it "should be blocking" do
          with_tcp_server(example_port) do |subject|
            expect(Celluloid::IO).not_to be_evented
          end
        end

        it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
          with_tcp_server(example_port) do |subject|
            thread = Thread.new { TCPSocket.new(example_addr, example_port) }
            peer   = subject.accept
            expect(peer).to be_a Celluloid::IO::TCPSocket

            client = thread.value
            client.write payload
            expect(peer.read(payload.size)).to eq payload
          end
        end
      end
    end
  end
end
