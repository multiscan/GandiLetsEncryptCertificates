#!/bin/sh
[ -d /tmp/self ] || mkdir -p /tmp/self

rm -f ./tmp/self/*
openssl req -config selfsigned.cfg -new -x509 -sha256 -newkey rsa:2048 -nodes -keyout tmp/self/key.pem -days 365 -out tmp/self/cert.pem
openssl x509 -in tmp/self/cert.pem -text -noout

