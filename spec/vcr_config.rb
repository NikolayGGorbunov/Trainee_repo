require 'vcr'
require 'rspec'

VCR.configure do |c|
  c.cassette_library_dir = "./vcr"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  vcr_mode = :once
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  WebMock.allow_net_connect!
end
