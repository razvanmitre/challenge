FROM phusion/passenger-ruby31

RUN apt-get update && apt upgrade -y && apt-get install -y \
  # Replace nginx with nginx-extras to have headers-more-nginx-module
  nginx-extras

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

# Define the user id
ENV APP_USER app

# Set Rails app environment. Used for the rails commands during provisioning

ENV RAILS_ENV production
# Set correct environment variables.
ENV HOME /home/$APP_USER

# App folder path
ENV APP_HOME $HOME/webapp

# Create app folder
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
VOLUME $APP_HOME/public/uploads

# Copy the Gemfiles and lock. Checkable if Gemfiles are the same
COPY Gemfile* $APP_HOME/
RUN bundle install --without test
RUN chown -R $APP_USER.$APP_USER $APP_HOME

# Nginx config
COPY docker/nginx/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY docker/nginx/gzip_max.conf /etc/nginx/conf.d/gzip_max.conf
COPY docker/nginx/passenger.conf /etc/nginx/conf.d/passenger.conf
COPY docker/nginx/env.conf /etc/nginx/main.d/env.conf

# Set passenger app environment based on RAILS_ENV
COPY docker/init/environment /etc/my_init.d/environment
# Add init script
COPY docker/init/init.sh /etc/my_init.d/init.sh
# Set scripts as executable
RUN chmod +x /etc/my_init.d/init.sh /etc/my_init.d/environment

# Copy the app files
COPY . $APP_HOME/

# Make sure that all the files and scripts are owned by the user running the app
RUN mkdir -p $APP_HOME/public/uploads/tmp && \
  mkdir -p $APP_HOME/log && \
  chown $APP_USER.$APP_USER $APP_HOME && \
  chown $APP_USER.$APP_USER $APP_HOME/* && \
  chown -R $APP_USER.$APP_USER $APP_HOME/app && \
  chown -R $APP_USER.$APP_USER $APP_HOME/bin && \
  chown -R $APP_USER.$APP_USER $APP_HOME/config && \
  chown -R $APP_USER.$APP_USER $APP_HOME/db && \
  chown -R $APP_USER.$APP_USER $APP_HOME/docker && \
  chown -R $APP_USER.$APP_USER $APP_HOME/lib && \
  chown -R $APP_USER.$APP_USER $APP_HOME/log && \
  chown -R $APP_USER.$APP_USER $APP_HOME/public
