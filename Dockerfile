FROM cimg/ruby:3.2-browsers

# Install Firefox and geckodriver from a tarball to avoid an issue where 
# geckodriver hangs when run in a container. 
# See https://firefox-source-docs.mozilla.org/testing/geckodriver/Usage.html#Running-Firefox-in-an-container-based-package
RUN wget -O FirefoxSetup.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
RUN tar xjf FirefoxSetup.tar.bz2
RUN sudo mv firefox /opt
RUN sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox
RUN wget -O geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux64.tar.gz
RUN tar zxvf geckodriver.tar.gz
RUN sudo mv geckodriver /usr/local/bin/geckodriver

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