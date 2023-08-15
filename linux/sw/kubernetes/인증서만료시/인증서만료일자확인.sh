#!/bin/bash
# kubeadm init 시 생성되는 인증서의 만료시간은 1년
# 인증서 만료일자 확인 script
for crt in /etc/kubernetes/pki/*.crt; do
    printf '%s: %s\n' \
    "$(date --date="$(openssl x509 -enddate -noout -in "$crt"|cut -d= -f 2)" --iso-8601)" \
    "$crt"
done | sort
