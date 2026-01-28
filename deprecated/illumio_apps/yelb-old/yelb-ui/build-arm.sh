# This script was used to rebuild the ui component for arm64 and push to my docker repo
# Should be no need to rebuild unless you change anything as my docker images can be used
# If it is rebuilt it should be built on an arm64 system
# Note to rebuild or run yelb on an arm64 system you will need the phantomjs binary.
# See phantomjs.txt in this directory
docker build -t mclemens68/yelb-ui:arm .
docker tag mclemens68/yelb-ui:arm mclemens68/yelb-ui:arm
docker push mclemens68/yelb-ui:arm
