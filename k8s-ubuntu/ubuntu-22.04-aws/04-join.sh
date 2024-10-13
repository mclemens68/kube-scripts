#!/bin/bash
kubeadm token create --print-join-command > join_cmd.txt
join_cmd=$(<join_cmd.txt)

ssh -t ubuntu@k8s-wk1-priv.clemenslabs.com 'sudo '$join_cmd
ssh -t ubuntu@k8s-wk2-priv.clemenslabs.com 'sudo '$join_cmd
