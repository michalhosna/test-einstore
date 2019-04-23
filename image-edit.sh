#!/bin/sh

ufw delete allow 2375/tcp
ufw delete allow 2376/tcp

sudo ufw allow http
sudo ufw allow https
