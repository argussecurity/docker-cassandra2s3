# Cassandra2S3

Cassandra to S3 backup script


## Usage

```
docker run --rm -it --net host \
  -e AWS_KEY=some_key \
  -e AWS_SECRET=some_secret \
  -e AWS_BUCKET=my-bucket \
  -e DB_USER=user \
  -e DB_PASS=pass \
  -e OUTPUT_NAME=dump.tar.gz \
  [-e IP=127.0.0.1] \
  argussecurity/cassandra2s3 keyspace1 keyspace2:table1 keyspace2:table2 [...]
```
