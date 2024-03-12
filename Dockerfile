FROM cimg/ruby:3.2-browsers
RUN gem install bundler -v '2.5.6'
RUN sudo mkdir /opt/tiger-data-app
RUN sudo chmod -R 777 /opt/tiger-data-app
WORKDIR /opt/tiger-data-app
COPY Gemfile Gemfile.lock package.json yarn.lock ./
RUN sudo chmod -R 777 /opt/tiger-data-app
RUN bundle install
RUN yarn install --check-files
COPY . .
RUN sudo chmod -R 777 /opt/tiger-data-app
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]