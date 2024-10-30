# This script was used to rebuild the appserver component for arm64 and push to my docker repo
# Should be no need to rebuild unless you change anything as my docker images can be used
# If it is rebuilt it should be built on an arm64 system
docker build -t mclemens68/yelb-appserver:arm .
docker tag mclemens68/yelb-appserver:arm mclemens68/yelb-appserver:arm
docker push mclemens68/yelb-appserver:arm
