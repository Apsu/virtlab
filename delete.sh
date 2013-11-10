#!/usr/bin/env bash

cd /opt/virtlab
source .venv/bin/activate
export PYTHONUNBUFFERED=1
ansible-playbook jenkins.yml delete.yml
