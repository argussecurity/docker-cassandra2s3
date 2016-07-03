# Cassandra2S3

Cassandra to S3 backup script


## Usage Example

```
docker run --rm -it --net host \
  -e AWS_KEY=some_key \
  -e AWS_SECRET=some_secret \
  -e AWS_BUCKET=my-bucket \
  -e DB_USER=user \
  -e DB_PASS=pass \
  -e OUTPUT_NAME=dump \
  [-e CQL_VERSION=3.1.7 \]
  [-e IP=127.0.0.1 \]
  [-e CLIENT_TIMEOUT=10 \]
  argussecurity/cassandra2s3 keyspace1 keyspace2:table1 keyspace2:table2 [...]
```

will export:

* keyspace1 - all tables
* keyspace2 - table1, table2

to CSV files, tar gzipped into a file named 'dump_$date.tar.gz' in S3 bucket 'my-bucket'.
