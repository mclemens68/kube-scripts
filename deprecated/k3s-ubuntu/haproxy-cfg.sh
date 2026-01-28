# Update /etc/haproxy/haproxy.cfg with new frontend IP's
# and restart haproxy
# run as sudo
echo 'defaults' > /etc/haproxy/haproxy.cfg
echo '    timeout connect 5s' >> /etc/haproxy/haproxy.cfg
echo '    timeout client 1m' >> /etc/haproxy/haproxy.cfg
echo '    timeout server 1m' >> /etc/haproxy/haproxy.cfg
echo '' >> /etc/haproxy/haproxy.cfg
echo 'frontend stats' >> /etc/haproxy/haproxy.cfg
echo '    mode http' >> /etc/haproxy/haproxy.cfg
echo '    bind *:8404' >> /etc/haproxy/haproxy.cfg
echo '    stats enable' >> /etc/haproxy/haproxy.cfg
echo '    stats uri /stats' >> /etc/haproxy/haproxy.cfg
echo '    stats refresh 10s' >> /etc/haproxy/haproxy.cfg
echo '    stats admin if TRUE' >> /etc/haproxy/haproxy.cfg
echo '' >> /etc/haproxy/haproxy.cfg
echo 'frontend guestbook-frontend' >> /etc/haproxy/haproxy.cfg
echo '    bind *:81' >> /etc/haproxy/haproxy.cfg
echo '    mode tcp' >> /etc/haproxy/haproxy.cfg
echo '    default_backend guestbook' >> /etc/haproxy/haproxy.cfg
echo 'frontend yelb-in' >> /etc/haproxy/haproxy.cfg
echo '    bind *:82' >> /etc/haproxy/haproxy.cfg
echo '    mode tcp' >> /etc/haproxy/haproxy.cfg
echo '    default_backend yelb' >> /etc/haproxy/haproxy.cfg
echo 'backend guestbook' >> /etc/haproxy/haproxy.cfg
echo '    mode tcp' >> /etc/haproxy/haproxy.cfg
echo '    server localhost '$(kubectl get service -n guestbook | grep frontend | cut -d' ' -f13)':80 check' >> /etc/haproxy/haproxy.cfg
echo 'backend yelb' >> /etc/haproxy/haproxy.cfg
echo '    mode tcp' >> /etc/haproxy/haproxy.cfg
echo '    server localhost '$(kubectl get service -n yelb | grep yelb-ui | cut -d' ' -f14)':80 check' >> /etc/haproxy/haproxy.cfg

service haproxy restart
