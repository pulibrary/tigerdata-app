FROM cimg/ruby:3.2-browsers
RUN sudo apt-get update -qq && sudo apt-get install -y firefox-geckodriver
RUN gem install bundler -v '2.5.6'
RUN sudo mkdir -p /opt/tiger-data-app/tmp/pids
RUN sudo chmod -R 777 /opt/tiger-data-app
WORKDIR /opt/tiger-data-app
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN sudo chmod -R 777 /opt/tiger-data-app
RUN bundle install
RUN yarn install --check-files
COPY . ./
RUN sudo chmod -R 777 /opt/tiger-data-app/tmp/pids
RUN sudo chmod -R 777 /opt/tiger-data-app/db
RUN sudo chmod -R 777 /opt/tiger-data-app/logs
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]