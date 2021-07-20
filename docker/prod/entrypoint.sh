#!/bin/bash

set -e
set -o pipefail

APACHE_PIDFILE=/run/apache2/apache2.pid
SERVER_NAME=${SERVER_NAME:="_default_"}

if [ -n "$DATABASE_URL" ]; then
	/usr/local/bin/migrate-mysql-to-postgres || exit 1
fi

# Warn when default hostname set
if [ "${SERVER_NAME}" = "_default_" ]; then
	echo "WARNING: You are using the default SERVER_NAME setting. If your docker container is public-facing, this is a security concern."
	echo "Please see https://www.openproject.org/docs/installation-and-operations/installation/docker/ for more information how to secure your installation."
fi

# handle legacy configs
if [ -d "$PGDATA_LEGACY" ]; then
	echo "WARN: You are using a legacy volume path for your postgres data. You should mount your postgres volumes at $PGDATA instead of $PGDATA_LEGACY."
	if [ "$(find "$PGDATA" -type f | wc -l)" = "0" ]; then
		echo "INFO: $PGDATA is empty, so $PGDATA will be symlinked to $PGDATA_LEGACY as a temporary measure."
		sed -i "s|$PGDATA|$PGDATA_LEGACY|" /etc/postgresql/9.6/main/postgresql.conf
		export PGDATA="$PGDATA_LEGACY"
	else
		echo "ERROR: $PGDATA contains files, so we will not attempt to symlink $PGDATA to $PGDATA_LEGACY. Please fix your docker configuration."
		exit 2
	fi
fi

if [ -d "$APP_DATA_PATH_LEGACY" ]; then
	echo "WARN: You are using a legacy volume path for your openproject data. You should mount your openproject volume at $APP_DATA_PATH instead of $APP_DATA_PATH_LEGACY."
	if [ "$(find "$APP_DATA_PATH" -type f | wc -l)" = "0" ]; then
		echo "INFO: $APP_DATA_PATH is empty, so $APP_DATA_PATH will be symlinked to $APP_DATA_PATH_LEGACY as a temporary measure."
		# also set ATTACHMENTS_STORAGE_PATH back to its legacy value in case it hasn't been changed
		if [ "$ATTACHMENTS_STORAGE_PATH" = "$APP_DATA_PATH/files" ]; then
			export ATTACHMENTS_STORAGE_PATH="$APP_DATA_PATH_LEGACY/files"
		fi
		export APP_DATA_PATH="$APP_DATA_PATH_LEGACY"
	else
		echo "ERROR: $APP_DATA_PATH contains files, so we will not attempt to symlink $APP_DATA_PATH to $APP_DATA_PATH_LEGACY. Please fix your docker configuration."
		exit 2
	fi
fi

if [ "$(id -u)" = '0' ]; then
	mkdir -p $APP_DATA_PATH/{files,git,svn}
	chown -R $APP_USER:$APP_USER $APP_DATA_PATH
	if [ -d /etc/apache2/sites-enabled ]; then
		chown -R $APP_USER:$APP_USER /etc/apache2/sites-enabled
		echo "OpenProject currently expects to be reached on the following domain: ${SERVER_NAME:=localhost}, which does not seem to be how your installation is configured." > /var/www/html/index.html
		echo "If you are an administrator, please ensure you have correctly set the SERVER_NAME variable when launching your container." >> /var/www/html/index.html
	fi

	# Clean up any dangling PID file
	rm -f $APP_PATH/tmp/pids/*

	# Clean up a dangling PID file of apache
	if [ -e "$APACHE_PIDFILE" ]; then
	  rm -f $APACHE_PIDFILE || true
	fi

	if [ ! -z "$ATTACHMENTS_STORAGE_PATH" ]; then
		mkdir -p "$ATTACHMENTS_STORAGE_PATH"
		chown -R "$APP_USER:$APP_USER" "$ATTACHMENTS_STORAGE_PATH"
	fi
	mkdir -p "$APP_PATH/log" "$APP_PATH/tmp/pids" "$APP_PATH/files"
	chown "$APP_USER:$APP_USER" "$APP_PATH"
	chown -R "$APP_USER:$APP_USER" "$APP_PATH/log" "$APP_PATH/tmp" "$APP_PATH/files" "$APP_PATH/public"

	# allow to launch any command as root by prepending it with 'root'
	if [ "$1" = "root" ]; then
		shift
		exec "$@"
	fi

	if [ "$1" = "./docker/prod/supervisord" ] || [ "$1" = "./docker/prod/proxy" ]; then
		exec "$@"
	fi

	exec $APP_PATH/docker/prod/gosu $APP_USER "$BASH_SOURCE" "$@"
fi

exec "$@"
