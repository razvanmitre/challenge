#!/bin/bash -x

# permissions
mkdir -p $APP_HOME/public/uploads/tmp
mkdir -p $APP_HOME/tmp/cache
chown -R $APP_USER.$APP_USER $APP_HOME/public/uploads
chown -R $APP_USER.$APP_USER $APP_HOME/tmp

logger 'db:migrate'
su $APP_USER -c 'rake log db:migrate'

logger 'System ready'
