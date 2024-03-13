FROM cimg/ruby:3.2-browsers

# Set the working directory
WORKDIR /opt/tiger-data-app

# Install ruby and js dependencies
RUN gem install bundler -v '2.5.6'
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN sudo chmod -R 777 /opt/tiger-data-app
RUN bundle install
RUN yarn install --check-files

# Copy the application into the container
COPY . ./

# Make all the directories and make them writable
RUN sudo chmod -R 777 /opt/tiger-data-app/db
RUN sudo mkdir -p /opt/tiger-data-app/tmp/pids
RUN sudo chmod -R 777 /opt/tiger-data-app/tmp/pids
RUN sudo mkdir -p /opt/tiger-data-app/log
RUN sudo chmod -R 777 /opt/tiger-data-app/log
RUN sudo mkdir -p /opt/tiger-data-app/tmp
RUN sudo chmod -R 777 /opt/tiger-data-app/tmp
RUN sudo chmod -R 777 /opt/tiger-data-app/public


EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]