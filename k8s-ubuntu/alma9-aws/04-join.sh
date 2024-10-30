#!/bin/bash
kubeadm token create --print-join-command > join_cmd.txt
join_cmd=$(<join_cmd.txt)

ssh -t ec2-user@k8s-wk1-a-priv.clemenslabs.com 'sudo '$join_cmd
ssh -t ec2-user@k8s-wk2-a-priv.clemenslabs.com 'sudo '$join_cmd
