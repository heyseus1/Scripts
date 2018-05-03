#!/bin/bash

configure_nginx ()
{
  cp /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
  echo "kqednet-nginx" >/etc/hostname
  rm -f /var/log/nginx/*
  cd /etc/nginx
  git pull git@10.22.0.212:Configs/kqednet-nginx-configs.git
  service nginx configtest
  service nginx reload
  service nginx restart
}
configure_nginx
