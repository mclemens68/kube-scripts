# example: pin guestbook/frontend to 32080 and yelb-ui to 30080
kubectl -n guestbook patch svc frontend -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":32080}]} }'
kubectl -n yelb patch svc yelb-ui -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30080}]} }'

