#!/bin/bash
set -e

# Environment variables
if [[ -z "$AWS_KEY" || -z "$AWS_SECRET" || -z "$AWS_BUCKET" || -z "$DB_USER" || -z "$DB_PASS" || -z "$OUTPUT_NAME" ]]; then
  echo "ERROR: All required environment variables must be defined."
  exit 1
fi

# Constants
BASE_PATH=/tmp/cassandra/dump
CQL_VERSION=${CQL_VERSION:-3.1.7}
IP=${IP:-$(hostname --ip)}


# Input:
#   cqlsh command to execute
# Output: CQLSH_RET
function cqlsh_exec {
  CQLSH_RET=$(cqlsh --cqlversion ${CQL_VERSION} -u ${DB_USER} -p ${DB_PASS} -e "$1" ${IP})
}

# Input:
#   keyspace
#   table
function export_table {
  keyspace=$1
  table=$2
  echo "Exporting table '$table'..."
  cqlsh_exec "USE $keyspace; COPY $table TO '$BASE_PATH/$keyspace-$table.csv'"
  echo "Done exporting table '$table'."
}

# Input:
#   keyspace
#   table (optional)
function export_db {
  keyspace=$1
  table=$2
  keyspace_tables=()
  if [[ -z ${table} ]]; then    # export all keyspace's tables
    cqlsh_exec "USE $keyspace; DESCRIBE TABLES" && cqlsh_ret=${CQLSH_RET}
    for row in ${cqlsh_ret}; do if [[ ${row} =~ ([a-z_]+) ]]; then keyspace_tables+=(${BASH_REMATCH[1]}); fi; done
  else                          # export only one table
    keyspace_tables+=(${table})
  fi
  for table in ${keyspace_tables[@]}; do
    export_table ${keyspace} ${table}
  done
  echo "Done exporting keyspace '$keyspace'."
}

# Input:
#   local file path
#   s3 file path
function put_s3 {
  local_path=$1
  s3_path=$2
  bucket=${AWS_BUCKET}
  date=$(TZ=utc date -R)
  content_type='application/x-compressed-tar'
  string="PUT\n\n$content_type\n$date\n/$bucket/$s3_path"
  signature=$(echo -en "${string}" | openssl sha1 -hmac "${AWS_SECRET}" -binary | base64)
  curl -X PUT -L -T "$local_path" \
    -H "Host: $bucket.s3.amazonaws.com" \
    -H "Date: $date" \
    -H "Content-Type: $content_type" \
    -H "Authorization: AWS ${AWS_KEY}:$signature" \
    "https://$bucket.s3.amazonaws.com/$s3_path"
}


# Execution

mkdir -p ${BASE_PATH}

echo "Exporting tables..."
for export_tuple in "$@"; do
  IFS=: read keyspace table <<< ${export_tuple}
  export_db ${keyspace} ${table}
done

echo "GZipping..."
tar -cvzf /tmp/dump.tar.gz -C ${BASE_PATH} .

output_path=${OUTPUT_NAME}_$(date "+%F-%T").tar.gz
echo "Uploading to S3 [$output_path]..."
put_s3 /tmp/dump.tar.gz ${output_path}
