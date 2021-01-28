# Johns Hopkins Catalyst ( Blacklight Library Catalog )
![CI Workflow](https://github.com/jhu-library-applications/catalyst-blacklight/workflows/CI/badge.svg?branch=main)

Catalyst is Johns Hopkins Libraries Catalog. It is an extention of the Blacklight project
which uses Solr as a central index. Catalyst.

This project is managed by the Library Applications, with production support (monitoring, backup, recovery, security) provided by Library Operations.

Catlayst also contains important subprojects
- horizon-holding-info-servlet : runs in jetty(8.1.4) connects to Horizon DB : looks up borrow info
- traject ( uses traject_horizon ) connects to Horizon DB and manages the Solr index

## Infrastructure Requirements

- Expternal IP (for BorrowDirect to work)

## Production

### catalyst.library.jhu.edu

## Development
config/database.php

### Docker for Development

Dockerfile, docker-compose.yml and env-example file add the ability to run a local containers. Docker use is experimental at this stage.

**Edit the env-example variables they are only examples**

Copy and edit the env-example file
```
cp env-example .env
```
Build catalyst containe (users Dockerfile)
```
docker-compose build
```
The mysql container uses a local volume to persist data
create the directory
```
mkdir .data
```

Start the mysql container and populate it with data
```
docker-compose up mysql
```
Populate the database from the development database
Get user, database passwords from catalyst config/database , and see you .env file for LOCAL details
```
docker-compose exec bash
db$  mysqldump --single-transaction --lock-tables=false --add-drop-table -h mysql.mse.jhu.edu -u <CAT_USER> -p <CAT_DB> > catalyst_db.sql
```
dump takes about a minute
the restore takes a lot longer

See the following documentation on version management and deployments:
```
db$  mysql -u <LOCAL_USER> -p <LOCAL_DB> < catalyst_db.sql
```
To bring the server up (-d is for deamon mode, run in background))
```
docker-composer up
```
Terminal into containers
```
docker-composer exec catalyst bash
docker-composer exec db bash
```
Navigate to http://localhost:3000 to access catalyst

### Tips on using Docker
Run a query inside the container
```
docker-compose exec db mysql -u catalyst -p catalyst -e  "select * from users limit 2"
```

**You will have to also edit the config/database.yml with the local database settings we can move to using the dotdenv gem at a later date**

## Components
Our implementation of Blacklight includes a lot of customization. To identify where we override or extend the Blacklight Gem, start from these folders under https://github.com/jhu-sheridan-libraries/blacklight-rails/tree/master/app
- Controllers
- Views
- Models
- Helpers
Compare the contents of these folders to the corresponding folders in the Blacklight Project Version 5.15

### Web Service for Borrower and Holdings Info from Horizon.
https://github.com/jhu-sheridan-libraries/horizon-holding-info-servlet/blob/master/README.md

### Traject
Indexes catalog records from Horizon to build the Solr index
https://github.com/jhu-sheridan-libraries/catalyst-traject

### Course Reserves
There are two parts to this feature.
1. Loader is in its own project
https://github.com/jhu-sheridan-libraries/catalyst-pull-reserves

2. Display of reserves info is controlled in this project
https://github.com/jhu-sheridan-libraries/blacklight-rails/blob/master/app/controllers/reserves_controller.rb

### Virtual Shelf Browse
This feature is a gem located at
https://github.com/jrochkind/rails_stackview

### My Account
This is a home-grown feature that includes a user login and various other functionality
- Login
https://github.com/jhu-sheridan-libraries/blacklight-rails/blob/master/app/controllers/user_sessions_controller.rb
- Other functionality
https://github.com/jhu-sheridan-libraries/blacklight-rails/blob/master/app/controllers/users_controller.rb

Note: My Account uses Horizon HIP service to handle requests, renewals, holds, etc.
https://github.com/jhu-sheridan-libraries/blacklight-rails/blob/master/lib/hip_pilot.rb


## Tips

VPN and then SSH tunnel to  a solr instance to test:
Check the tunnel worked in another window

ssh -L 8983:localhost:8080 fsadiq1@solr03.mse.jhu.edu
curl http://localhost:8983/solr/#/catalyst_dev1

# Check difference with production, which is tagged
git diff production-2017-05-05-1357

# Tests with Cucumber

Prerequisites:

Install chromedriver. On mac:

```
brew install chromedriver
```

Note: if you see an error such as the following, it means that chromedriver needs to be udpated.
```
      unknown error: call function result missing 'value'
        (Session info: headless chrome=65.0.3325.162)
        (Driver info: chromedriver=2.32.498537 (cb2f855cbc7b82e20387eaf9a43f6b99b6105061),platform=Mac OS X 10.13.3 x86_64) (Selenium::WebDriver::Error::UnknownError)
```

Try the following:

```
chromedriver-update 2.36
```

## Test Catalyst

To test with localhost, just run

```
RAILS_ENV=test bundle exec cucumber
```

To test with a single scenario, use `featrures/file_name.feature:line_number`, for example

```
RAILS_ENV=test bundle exec cucumber features/basic_search.feature:9
```

To test a non-localhost server, add a `CAPYBARA_APP_HOST` environment variable

```
RAILS_ENV=test CAPYBARA_APP_HOST=https://catalyst-test.library.jhu.edu bundle exec cucumber
```

, or put it in `.env`:

```
CAPYBARA_APP_HOST=https://catalyst-test.library.jhu.edu
```

## Test services that Catalyst depends on

By default, the cucumber tests only test Catalyst features. External services not
included in the Rails app will not be tested.
To test these services, such as horizon servlet service and hip service, use the following:

```
RAILS_ENV=test bundle exec cucumber -p servcies
```

To test a certain HIP server, try

```
HIP_HOST=hip-test.library.jhu.edu RAILS_ENV=test bundle exec cucumber -p services
```

Note: the profiles are defined in `config/cucumber.yml`

# Disable Patron Account Features

During Horizon upgrade, we need to disable patron account features, while allowing patrons to use
other catalyst features.

In `config/initializers/disable_hip.rb`, set
```
JHConfig.params[:disable_hip] = true
```
, and in the same file, update the texts in
```
JHConfig.params[:disable_hip_message]
```

## Version management documentation:
https://jhulibraries.atlassian.net/wiki/spaces/CATALYST/pages/31555838/Git+Organization+and+Deployment+Flow

## Deployment documentation:
https://github.com/jhu-sheridan-libraries/catalyst-ansible
