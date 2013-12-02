#!/usr/bin/env bash

cd /opt/virtlab
source .venv/bin/activate
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
ansible-playbook jenkins.yml build.yml $@ 2>&1
