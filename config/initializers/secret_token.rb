# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Catalyst::Application.config.secret_token    = '34c1d31dc108011fd3743378289ce7bddc036338a176da187d634cab4810dcf147bb878f2ea520da2a06c2a0763f76386d50f6661bde280dd7581b28dc8ef674'
Catalyst::Application.config.secret_key_base = '0f620ede6f3974870c708c75bb3e27ed0de8dbeaf550292405d7fea38af35bb788e3fd74dad7c3c2d479a683d5100c428c0e30a2bd6df75c9e7fc3dc3791a2bd'

# Use a different secret token for our weird scheme that
# encrypts record IDs in refworks export callback urls,
# to prevent people from mass scraping RIS from us.
# Note: This may need to be truncated to 32 bits after upgrading to ruby 2.4.3. See https://github.com/rails/rails/issues/25448
# Note: During the upgrade to Rails 5, reduced key length, seems incorrect
Catalyst::Application.config.refworks_callback_secret_token = 'e719fba1204c5c36d5da0dc01514e146'
