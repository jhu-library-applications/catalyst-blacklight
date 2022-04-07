.PHONY: up
up:
	docker-compose build \
	&& docker-compose run --rm catalyst gem install bundler \
	&& docker-compose run --rm catalyst bundle install -j2	\
	&& docker-compose run -e RAILS_ENV=development --rm catalyst rails db:create  \
	&& docker-compose run -e RAILS_ENV=development --rm catalyst rails db:migrate \
	&& docker-compose up -d

.PHONY: test
test:
	docker-compose build \
	&& docker-compose run --rm catalyst gem install bundler \
	&& docker-compose run --rm catalyst bundle install -j2	\
	&& docker-compose run -e RAILS_ENV=test --rm catalyst rails db:create  \
	&& docker-compose run -e RAILS_ENV=test --rm catalyst rails db:migrate \
	&& docker-compose run -e RAILS_ENV=test --rm catalyst yarn \
	&& docker-compose run -e RAILS_ENV=test -e RUBYOPT='-W0' --rm catalyst bundle exec rake ci
