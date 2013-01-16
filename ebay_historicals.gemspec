$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ebay_historicals/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ebay_historicals"
  s.version     = EbayHistoricals::VERSION
  s.authors     = ["Chris Mozzocchi"]
  s.email       = ["cmozzocchi@gmail.com"]
  s.homepage    = "http://github.com/cmozzocchi"
  s.summary     = "A gem to interface with Terapeak and Ebay APIs"
  s.description = "This gem will allow your rails app to interact with TeraPeak's api to access historical Ebay selling prices. It will also allow the developer to call Ebay's API in order to search for the correct products to find historical selling prices on as well as currently available products"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.11"
  s.add_dependency "nokogiri"

  s.add_development_dependency "sqlite3"
end
