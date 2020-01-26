FROM stlouisn/ubuntu:rolling

COPY rootfs /

RUN \

    export DEBIAN_FRONTEND=noninteractive && \

    # Update apt-cache
    apt-get update && \

    # Create mysql group
    groupadd \
        --system \
        --gid 9999 \
        mysql && \

    # Create mysql user
    useradd \
        --system \
        --no-create-home \
        --shell /sbin/nologin \
        --comment mysql \
        --gid 9999 \
        --uid 9999 \
        mysql && \

    # Install mariadb
    apt-get install -y --no-install-recommends \
        mariadb-client \
		mariadb-backup \
        mariadb-server && \

    # Install pwgen
    apt-get install -y --no-install-recommends \
        pwgen && \

	# Purge and re-create /var/lib/mysql with appropriate ownership
	rm -rf /var/lib/mysql && \
	mkdir -p /var/lib/mysql && \
	chown -R mysql:mysql /var/lib/mysql && \

	# Ensure that /var/run/mysqld is created with appropriate ownership
	mkdir -p /var/run/mysqld && \
	chown -R mysql:mysql /var/run/mysqld && \
	chmod 777 /var/run/mysqld && \

	# Ensure that /docker-entrypoint-initdb.d is created
	mkdir -p /docker-entrypoint-initdb.d && \

	# Comment out problematic configuration values
	find /etc/mysql/ -name '*.cnf' -print0 \
		| xargs -0 grep -lZE '^(bind-address|log)' \
		| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' && \

    # Clean apt-cache
    apt-get autoremove -y --purge && \
    apt-get autoclean -y && \

    # Cleanup temporary folders
    rm -rf \
        /root/.cache \
        /root/.wget-hsts \
        /tmp/* \
        /var/lib/apt/lists/*

VOLUME /var/lib/mysql

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]

CMD ["mysqld"]
