#!/bin/bash
set -e

# Environment variables
if [[ -z "$DB_USER" || -z "$DB_PASS" || -z "$INPUT_DIR" ]]; then
  echo "ERROR: All required environment variables must be defined."
  exit 1
fi

# Constants
BASE_PATH=${INPUT_DIR}
CQL_VERSION=${CQL_VERSION:-3.1.7}
IP=${IP:-$(hostname --ip)}
CLIENT_TIMEOUT=${CLIENT_TIMEOUT:-10}


function init_cqlsh {
  mkdir ~/.cassandra
  printf "[connection]\nclient_timeout = $CLIENT_TIMEOUT" > ~/.cassandra/cqlshrc
}

# Input:
#   cqlsh command to execute
# Output: CQLSH_RET
function cqlsh_exec {
  CQLSH_RET=$(cqlsh --cqlversion ${CQL_VERSION} -u ${DB_USER} -p ${DB_PASS} -e "$1" ${IP})
}

# Input:
#   keyspace
#   table
function import_table {
  keyspace=$1
  table=$2
  echo "Importing table '$table'..."
  cqlsh_exec "USE $keyspace; COPY $table FROM '$BASE_PATH/$keyspace-$table.csv' WITH PAGETIMEOUT=$CLIENT_TIMEOUT"
  echo "Done importing table '$table'."
}

# Input:
#   keyspace
#   table (optional)
function import_db {
  keyspace=$1
  table=$2
  keyspace_tables+=(${table})
  for table in ${keyspace_tables[@]}; do
    import_table ${keyspace} ${table}
  done
  echo "Done importing keyspace '$keyspace'."
}


# Execution

init_cqlsh

echo "Importing tables..."
for import_tuple in "$@"; do
  IFS=: read keyspace table <<< ${import_tuple}
  import_db ${keyspace} ${table}
done
