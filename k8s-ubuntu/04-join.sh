#!/bin/bash
kubeadm token create --print-join-command > join_cmd.txt
join_cmd=$(<join_cmd.txt)

ssh -t matt@turingpi2 'sudo '$join_cmd
ssh -t matt@turingpi3 'sudo '$join_cmd
ssh -t matt@turingpi4 'sudo '$join_cmd
