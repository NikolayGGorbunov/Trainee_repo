require 'rspec'
require 'vcr'
require 'yaml'
require_relative '../mapbox_task/first.rb'

RSpec.describe DeliveryBoy do
  VCR.configure do |c|
    c.cassette_library_dir = "vcr"
    c.hook_into :webmock
    c.configure_rspec_metadata!
    vcr_mode = :once
  end

  describe "#package_type" do
    subject(:instance) {described_class.package_type(weight, length, width, height)}

    context "given size less then 1 cubic meter" do
      let(:weight) {1}
      let(:length) {1}
      let(:width) {1}
      let(:height) {1}
      it "return 1" do
        expect(instance).to eq(1)
      end
    end

    context "given size more then 1 cubic meter and weight less then 10 kg" do
      let(:weight) {1}
      let(:length) {200}
      let(:width) {200}
      let(:height) {200}
      it "return 2" do
        expect(instance).to eq(2)
      end
    end

    context "given size more then 1 cubic meter and weight more then 10 kg" do
      let(:weight) {10.3}
      let(:length) {200}
      let(:width) {200}
      let(:height) {200}
      it "return 3" do
        expect(instance).to eq(3)
      end
    end

    context "given negative params" do
      let(:weight) {-20}
      let(:length) {-200}
      let(:width) {-200}
      let(:height) {-200}
      it "raise 'wrong argument' error" do
        expect{instance}.to raise_error(RuntimeError, "Wrong arguments")
      end
    end
  end

  describe "#get_cities_cords" do
    subject(:instance) {described_class.get_cities_cords(city1, city2)}

    context "given two different valid cities" do
      let(:city1) {"krasnodar"}
      let(:city2) {"moscow"}
      it "return array with two elements" do
        VCR.use_cassette "get cities raw krasnodar-moscow" do
          expect(instance).to be_kind_of(Array)
          expect(instance.size).to eq(2)
        end
      end
      it "return city1 to city2 cords right" do
        VCR.use_cassette "get cities raw krasnodar-moscow" do
          expect(instance[0]).to eq([37.61778, 55.75583])
          expect(instance[1]).to eq([38.98333, 45.03333])
        end
      end
    end

    context "given same city twice" do
      let(:city1) {"moscow"}
      let(:city2) {"moscow"}
      it "raise 'same city' error" do
        expect{instance}.to raise_error(RuntimeError, "Choose different cities")
      end
    end

    context "given fake cities" do
      let(:city1) {"bjgdhbsjhgbsdg"}
      let(:city2) {"sojdamsdbasfdvasf"}
      it "raise 'city not found' error" do
        VCR.use_cassette "get cities raw no city" do
          expect{instance}.to raise_error(RuntimeError, "City not found")
        end
      end
    end
  end

  describe "#get_distance" do
    subject(:instance) {described_class.get_distance(cords1, cords2)}

    context "given cords in right format" do
      let(:cords1) {[37.61778, 55.75583]}
      let(:cords2) {[38.98333, 45.03333]}
      it "return distance in right format" do
        VCR.use_cassette "get distance krasnodar-moscow" do
          expect(instance).to be_kind_of(Integer)
          expect(instance).to be > 0
        end
      end
      it "return right distance in km" do
        VCR.use_cassette "get distance krasnodar-moscow" do
          expect(instance).to eq(1350)
        end
      end
    end

    context "when there's no way between cords" do
      let(:cords1) {[38.98333, 45.03333]}
      let(:cords2) {[69.3423428366489, 88.21364245388949]}
      it "raise 'no route' error" do
        VCR.use_cassette "get distance no route" do
          expect{instance}.to raise_error(RuntimeError,"No route")
        end
      end
    end
  end

  describe '#give_package' do
    subject(:instance) {described_class.give_package(data)}

    context "given size < 1 cubic meter and correct city names" do
      let(:data) {{weight: 5, length:1, width:1, height:1, city1_name:"krasnodar", city2_name:"moscow"}}
      it "return 1st type of package price (==distance)" do
        VCR.use_cassette "give package valid" do
          expect(instance).to be_kind_of(Hash)
          expect(instance).to include({distance:1350, price:1350})
        end
      end
    end

    context "given size > 1 cubic meter, weight < 10 kg and correct city names" do
      let(:data) {{weight: 5, length:200, width:200, height:200, city1_name:"krasnodar", city2_name:"moscow"}}
      it "return 2nd type of package price (==distance*2)" do
        VCR.use_cassette "give package valid" do
          expect(instance).to be_kind_of(Hash)
          expect(instance).to include({distance:1350, price:1350*2})
        end
      end
    end

    context "given size > 1 cubic meter, weight > 10 kg and correct city names" do
      let(:data) {{weight: 11, length:200, width:200, height:200, city1_name:"krasnodar", city2_name:"moscow"}}
      it "return 3rd type of package price (==distance*3)" do
        VCR.use_cassette "give package valid" do
          expect(instance).to be_kind_of(Hash)
          expect(instance).to include({distance:1350, price:1350*3})
        end
      end
    end
  end
end
