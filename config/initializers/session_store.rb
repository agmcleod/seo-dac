# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_seo_session',
  :secret      => 'a668fc52793aceb62b1b123dde68147443c4f091db41ffd5836932d1a565b65d0d23d97bac2481022c2b01f73ad8cd433b416d5a1249f753eafb991c9aca27ad'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
