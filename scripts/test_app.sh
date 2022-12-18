#!/bin/bash
set -e

if [[ ${deployment_location} == "DOCKER" ]];
then
    echo "Running tests from inside docker container"
    CERT_PATH=/sandbox_common
    CCF_PORT=8080
    # VENV_DIR=/app/.venv_ccf_sandbox
    # source "${VENV_DIR}"/bin/activate
else
    echo "Running tests locally"
    CERT_PATH=$(pwd)/../sandbox_common
    CCF_PORT=8546
    sudo chmod +r $CERT_PATH/user0*
    sudo chmod +r $CERT_PATH/user1*
    sudo chmod +r $CERT_PATH/member0*
fi
ccf_server="https://localhost:$CCF_PORT"

only_status_code="-s -o /dev/null -w %{http_code}"
hash_0="e7a3f808cb0687fd3660e956a5df0f00e23edac5650769ec354ee670b658858c"
hash_1="1ea442a134b2a184bd5d40104401f2a37fbc09ccf3f4bc9da161c6099be3691d"
hash_result="7c0e3b351432e5d3f3677e7afb78b6c5fa0f2944f3bead994a9a1cc73c892901"

user0_id=$(openssl x509 -in "$CERT_PATH/user0_cert.pem" -noout -fingerprint -sha256 | cut -d "=" -f 2 | sed 's/://g' | awk '{print tolower($0)}')
user1_id=$(openssl x509 -in "$CERT_PATH/user1_cert.pem" -noout -fingerprint -sha256 | cut -d "=" -f 2 | sed 's/://g' | awk '{print tolower($0)}')
user_fake="1ea442a134b2a184bd5d40104401f2a37fbc09ccf3f4bc9da161c6099be3691d"


check_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" == "$actual" ]; then
        echo -e "\t✅ [Pass]: $test_name" 
    else
        echo -e "\t❌ [Fail]: $test_name: $expected expected, but got $actual."
        cat out.json | jq .
        # exit 1
    fi
}

check_status() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" == "$actual" ]; then
        echo -e "\t✅ [Pass]: $test_name" 
    else
        echo -e "\t❌ [Fail]: $test_name: status $expected expected, but got $actual."
        # exit 1
    fi
}

cert_arg() {
    caller="$1"
    echo " --cacert $CERT_PATH/service_cert.pem --cert $CERT_PATH/${caller}_cert.pem --key $CERT_PATH/${caller}_privk.pem"
}


echo -e "\n\nTesting /app/scs/<userid> GET path failure cases"

status="$(curl "$ccf_server/app/scs/$user1_id" -X GET $(cert_arg "user1") $only_status_code)"
check_status "/app/scs/<userid> GET on nonexistant user" "404" "$status"

status="$(curl "$ccf_server/app/scs/$user_fake" -X GET $(cert_arg "user0") $only_status_code)"
check_status "/app/setup/<userid> GET with incorrect userid" "403" "$status"


echo -e "\n\nTesting /app/setup/<userid> POST path"

status="$(curl "$ccf_server/app/setup/$user_fake" -X POST --data "{\"hash\": \"$hash_0\"}" $(cert_arg "user0") $only_status_code)"
check_status "/app/setup/<userid> POST with incorrect userid" "403" $status

status="$(curl "$ccf_server/app/setup/$user1_id" -s -X POST --data "{\"hash\": \"$hash_0\"}" $(cert_arg "user0") $only_status_code)"
check_status "/app/setup/<userid> POST with inconsistant userid and credentials" "403" $status

curl "$ccf_server/app/setup/$user0_id" -s -X POST --data '{"hash": "hello world"}'  $(cert_arg "user0") > out.json 
error="$(cat out.json | jq .error)"
expect="\"Invalid hash\""
check_eq "/app/setup/<userid> POST with invalid hash" "$expect" "$error"

status="$(curl "$ccf_server/app/setup/$user0_id" -X POST --data "{\"hash\": \"$hash_0\"}"  $(cert_arg "user0") $only_status_code)"
check_status "/app/setup/<userid> POST" "204" $status

curl "$ccf_server/app/setup/$user0_id" -s -X POST --data "{\"hash\": \"$hash_1\"}"   $(cert_arg "user0")  > out.json 
error=$(cat out.json| jq .error) 
expect="\"Record for userId: \\\"$user0_id\\\" already exists\""
check_eq "/app/setup/<userid> POST existing user" "$expect" "$error"


echo -e "\n\nTesting /app/scs/<userid> GET path"
curl "$ccf_server/app/scs/$user0_id" -s -X GET  $(cert_arg "user0") > out.json 
ret_hash=$(cat out.json| jq .hash) 
check_eq "/app/scs/<userid> GET" "\"$hash_0\"" "$ret_hash"

# curl "$ccf_server/app/scs/$user0_id" -s -X GET -H "Content-Type:application/json" --cacert "$CERT_PATH/service_cert.pem" --cert "$CERT_PATH/user1_cert.pem" --key "$CERT_PATH/user1_privk.pem" | jq .
status="$(curl "$ccf_server/app/scs/$user0_id" -s -X GET $(cert_arg "user1") $only_status_code)"
check_status "/app/scs/<userid> GET with inconsistant userid and credentials" "403" $status


echo -e "\n\nTesting /app/scs/<userid> POST path"
curl "$ccf_server/app/scs/$user0_id" -s -X POST --data '{"hash": "goodbye"}' $(cert_arg "user0") > out.json
error=$(cat out.json| jq .error) 
expect="\"Invalid hash\""
check_eq "/app/scs/<userid> POST with invalid hash" "$expect" "$error"

status="$(curl "$ccf_server/app/scs/$user0_id" -X POST -i --data "{\"hash\": \"$hash_1\"}" $(cert_arg "user0") $only_status_code)"
check_status "/app/scs/<userid> POST" "200" $status

curl "$ccf_server/app/scs/$user0_id" -s -X GET $(cert_arg "user0") > out.json 
ret_hash=$(cat out.json| jq .hash) 
check_eq "/app/scs/<userid> POST result" "\"$hash_result\"" "$ret_hash"

transaction_id=$(curl "$ccf_server/app/scs/$user0_id" -X POST -i  -s --data "{\"hash\": \"$hash_1\"}" $(cert_arg "user0") | grep -i x-ms-ccf-transaction-id | awk '{print $2}' | sed -e 's/\r//g')
# Wait for receipt to be ready

echo -e "\n\nTesting /app/receipt/<userid> GET path"
timeout=10
total=0
while [ "200" != "$(curl $ccf_server/app/receipt/$user0_id?transaction_id=$transaction_id $(cert_arg "user0") $only_status_code)" ]
do
    t=1
    sleep $t
    total=$((total + t))
    if  (( $total > $timeout )); then 
      curl "$ccf_server/app/receipt/$user0_id?transaction_id=$transaction_id" -s -X GET $(cert_arg "user0") | jq .
      echo "timeout exceeded exiting after $total seconds"
      exit 1
    fi
done

curl "$ccf_server/app/receipt/$user0_id?transaction_id=$transaction_id" -s -X GET $(cert_arg "user0") > out.json 
verify_res=$(python3.8 utils.py verify_receipt out.json)
check_eq "Verify receipt" "OK" "$verify_res"


echo -e "\n\nTesting /app/reset path"

status="$(curl "$ccf_server/app/reset/$user0_id" -X PUT $(cert_arg "user0") $only_status_code)"
check_status "/app/reset/<userid> with user credentials" "401" $status

status="$(curl "$ccf_server/app/reset/$user0_id" -X PUT $(cert_arg "member0") $only_status_code)"
check_status "/app/reset/<userid> with member credentials" "202" $status

status="$(curl "$ccf_server/app/reset/$user0_id" -X PUT $(cert_arg "user0") $only_status_code)"
check_status "/app/reset/<userid> user0 data deleted" "401" $status

echo -e "\n\nTesting /app/reset/<userid> GET path failures (after reset)"
status="$(curl "$ccf_server/app/scs/$user0_id" -X GET $(cert_arg "user0") $only_status_code)"
check_status "/app/reset/<userid> GET on nonexistant user (after reset)" "404" $status