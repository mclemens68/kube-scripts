
# Need both python3 and yq installed for this script to work. Both can be installed via Brew on a Mac
# brew install python3
# brew install yq

if [ $# -eq 0 ]
  then
    echo "Run script with the workloader pce name as an argument"
    echo "Run workloader pce-list to get list of pce's"
    exit 1
fi

PCE_NAME=$1

# If ILLUMIO_CONFIG is not set assume pce.yaml is in current working directory
CONFIG="${ILLUMIO_CONFIG:=./pce.yaml}"

echo $CONFIG

ILO_API_TOKEN=$(cat $CONFIG | yq -r ".${PCE_NAME} | [.key] | @tsv")
echo $ILO_API_TOKEN
ILO_API_KEY=$(cat $CONFIG | yq -r ".${PCE_NAME} | [.user] | @tsv")
echo $ILO_API_KEY
ILO_ORG=$(cat $CONFIG | yq -r ".${PCE_NAME} | [.org] | @tsv")
echo $ILO_ORG
ILO_FQDN=$(cat $CONFIG | yq -r ".${PCE_NAME} | [.fqdn] | @tsv")
echo $ILO_FQDN
ILO_PORT=$(cat $CONFIG | yq -r ".${PCE_NAME} | [.port] | @tsv")
echo $ILO_PORT
ILO_SERVER=https://$ILO_FQDN:$ILO_PORT
echo $ILO_SERVER
 
curl -X POST "${ILO_SERVER}/api/v2/orgs/${ILO_ORG}/container_clusters" \
-u ${ILO_API_KEY}:${ILO_API_TOKEN} \
-H "Content-Type: application/json" \
-d '{"name":"kube-test","description":"test cluster"}'

echo "\n"
