.PHONY: up
up:
	docker-compose build \
	&& docker-compose run --rm catalyst gem install bundler \
	&& docker-compose run --rm catalyst bundle install -j4	\
	&& docker-compose run -e RAILS_ENV=development --rm catalyst rails db:create  \
	&& docker-compose run -e RAILS_ENV=development --rm catalyst rails db:migrate \
	&& docker-compose up -d

.PHONY: test
test:
	docker-compose build \
	&& docker-compose run --rm catalyst gem install bundler \
	&& docker-compose run --rm catalyst bundle install -j4	\
	&& docker-compose run -e RAILS_ENV=test --rm catalyst bundle exec rails db:create  \
	&& docker-compose run -e RAILS_ENV=test --rm catalyst bundle exec rails db:migrate \
	&& docker-compose run -e RAILS_ENV=test -e RUBYOPT='-W0' --rm catalyst bundle exec rails test \
	&& docker-compose run -e RAILS_ENV=test --rm catalyst bundle exec rails assets:precompile \
	&& docker-compose run -e RAILS_ENV=test -e RUBYOPT='-W0' --rm catalyst bundle exec rails test:system

.PHONY: ci
ci:
	docker-compose build \
	&& docker-compose run catalyst gem install bundler \
	&& docker-compose run -e RAILS_ENV=test catalyst -v bundler_gems:/catalyst/vendor/bundle bundle exec rails db:create  \
	&& docker-compose run -e RAILS_ENV=test catalyst -v bundler_gems:/catalyst/vendor/bundle bundle exec rails db:migrate \
	&& docker-compose run -e RAILS_ENV=test -e RUBYOPT='-W0' -v bundler_gems:/catalyst/vendor/bundle catalyst bundle exec rails test \
	&& docker-compose run -e RAILS_ENV=test -v bundler_gems:/catalyst/vendor/bundle catalyst bundle exec rails assets:precompile \
	&& docker-compose run -e RAILS_ENV=test -e RUBYOPT='-W0' -v bundler_gems:/catalyst/vendor/bundle bundle exec rails test:system
