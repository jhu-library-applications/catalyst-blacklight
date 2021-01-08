# Catalyst Upgrade / Development

This file contains information about work completed on the Catalyst Upgrade project. We intend to upgrade the application to: Ruby 2.6+, Rails 5.2+, Blacklight 7+, Solr 7+.

## Catalyst Local Dev
brew install mysql@5.7 \
brew link mysql@5.7 --force \
brew install mysql-connector-c

### Install Required Ruby Version
ruby-install ruby 2.6.5 \
chruby ruby-2.6.5

### Create Bash Configs for MySql and ChRuby
vi  ~/.bash_profile with the following contents: \
source /usr/local/opt/chruby/share/chruby/chruby.sh \
source /usr/local/opt/chruby/share/chruby/auto.sh \
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH" \
cp .bash_profile  .bashrc

### Install Gems
cd blacklight-rails \
gem install bundler \
bundle install --path vendor/bundle

### Create Local Environment Configurations
cp /opt/catalyst/.env.development blacklight-rails \
Update passwords from LastPass in .env.development

### Run Catalyst
Open RubyMine \
Open blacklight-rails \
Check sdk configurations \
Open RubyMine | Preferences \
Languages & Frameworks | Ruby SDK and Gems \
Ensure chruby: ruby-2.6.5 sdk is selected \
Run the server Run | Run 'Development: blacklight-rails' \
Navigate to localhost:3000 to view the application

## Solr

I have added support for a localized Solr installation using SolrWrapper -- using a local solr instance is how Blacklight and GeoBlacklight development is typically done.

* .solr_wrapper - for configuration and specifics
* /solr  - directory where conf lives
* /tmp/blacklight-core where the instance lives

## Traject

To index a small set of records for local testing, I have added Traject and JHU's configuration files directly to the project.

* /traject
* JHU's Traject configuration is used to index the documents
* /test/fixtures/files are where the MARC records live for ingest
* /test/fixtures/files/_combined.mrc is all of the individual binary files concatenated via MarcEdit

Currently, due to an old blacklight-marc dependency, the application uses Traject v2 to index the records from _combined.mrc. If we can move to Traject v3+ we should be able to index the individual records without needing to concatenate them altogether into a single file.

## Development

### Run the Horizon Holding Info Servlet

This application and test suite both rely on holdings data from Horizon. You'll need to clone, build, and run the [horizon-holding-info-servlet](https://github.com/jhu-sheridan-libraries/horizon-holding-info-servlet) locally.

To run the servlet, sign onto the JHU VPN, then:
```
cd <servlet project root>
mvn jetty:run
```

### Run Solr and App

To run the application for development work use the following rake task:

```
bundle exec rake jhu:server
```

You'll see Solr running on [localhost:8983](http://localhost:8983/) and the rails application on [localhost:3000](http://localhost:3000/)

### Run Solr in Test Environment

When you are writing or running tests, it can be helpful to run only Solr in test mode (port 8985):

```
RAILS_ENV=test bundle exec rake jhu:test
```

You'll see Solr running on [localhost:8985](http://localhost:8985/)

Now, in a separate terminal window, run the test suite

```
RAILS_ENV=test bundle exec rake test
RAILS_ENV=test bundle exec rake test test:system
```

### Run Solr in Development Environment

```
bundle exec rake jhu:development
```

## Tests

### Run All Tests for Continuous Integration

```
RAILS_ENV=test bundle exec rake ci
```

To silence deprecation warnings, because Blacklight can throw many upstream warnings, pass along this option:

```
RUBYOPT=W0 RAILS_ENV=test bundle exec rake ci
```

### Test Development

#### Spin up test solr

```
RAILS_ENV=test bundle exec rake jhu:test
```

#### Run tests (new terminal window)

```
RAILS_ENV=test bundle exec rake test             # Runs test suite (use the most)
RAILS_ENV=test bundle exec rake test:system      # Runs system tests (when UI needs testing)
RAILS_ENV=test bundle exec rake test test:system # Runs test suite and system tests
RAILS_ENV=test bundle exec rails test test/controllers/catalog_controller_test.rb # Run just a single test file

```
