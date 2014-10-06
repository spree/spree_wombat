require "spec_helper"

describe Spree::Wombat::Client do

  describe "#push_batches" do
    it "does not update last push timestamp when exception occurs" do
      prev_push_time = 2.days.ago
      Spree::Wombat::Config[:last_pushed_timestamps]["Spree::Order"] = prev_push_time
      time_now = Time.parse(Time.now.to_s)
      Time.stub(:now).and_return(time_now)

      Object.any_instance.stub_chain(:where, :find_in_batches).and_raise(ActiveRecord::ConnectionTimeoutError)
      Spree::Wombat::Client.push_batches("Spree::Order")
      Spree::Wombat::Config[:last_pushed_timestamps]["Spree::Order"].should == prev_push_time
    end
  end

end
