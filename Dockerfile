FROM mesosphere/cqlsh
ADD backup.sh /usr/app/backup.sh
ENTRYPOINT /usr/app/backup.sh
