require 'json'
require 'pry'
require 'net/http'

class DeliveryBoy
  def self.give_package(hsh = {})
    cords1, cords2 = get_cities_cords(hsh[:city1_name], hsh[:city2_name])
    distance = get_distance(cords1, cords2)
    price_mul = package_type(hsh[:weight], hsh[:length], hsh[:width], hsh[:height])
    hsh.slice(:weight, :length, :width, :height).merge!({distance: distance, price: distance*price_mul})
  end

  private
  def self.get_cities_cords(city1, city2)
    raise "Choose different cities" if city1.downcase == city2.downcase

    uri = URI("https://api.mapbox.com/geocoding/v5/mapbox.places/#{city1.to_s.downcase}%2C#{city2.to_s.downcase}.json?country=ru&limit=2&proximity=ip&types=place&access_token=pk.eyJ1Ijoibmlrb2xhaWdvcmJ1bm92IiwiYSI6ImNsNm5veDg1ZDAyd2Yzam1sbnprZnAwYTYifQ.Ix2UzqHEHVU0E1-jqXsB4Q")
    response = Net::HTTP.get(uri)
    par = JSON.parse(response)
    raise "City not found" if par["features"].size < 2
    city1_cord = par["features"][0]["center"]
    city2_cord = par["features"][1]["center"]
    [city1_cord,city2_cord]
  end

  def self.get_distance(cords1, cords2)
    uri = URI("https://api.mapbox.com/directions/v5/mapbox/driving/#{cords1[0]}%2C#{cords1[1]}%3B#{cords2[0]}%2C#{cords2[1]}?alternatives=false&geometries=geojson&overview=simplified&steps=false&access_token=pk.eyJ1Ijoibmlrb2xhaWdvcmJ1bm92IiwiYSI6ImNsNm5veDg1ZDAyd2Yzam1sbnprZnAwYTYifQ.Ix2UzqHEHVU0E1-jqXsB4Q")
    response = Net::HTTP.get(uri)
    par = JSON.parse(response)
    raise "No route" if par["code"].include?("NoSegment") || par["code"].include?("NoRoute")
    distance = par["routes"].first["distance"]
    (distance/1000).round
  end

  def self.package_type(weight,length,width,height)
    if weight < 0 || length <= 0 || width <= 0 || height <= 0
      raise "Wrong arguments"
    end
    cubic = length*width*height
    if cubic < 1000000
      return 1
    elsif weight <= 10
      return 2
    else
      return 3
    end
  end
end
