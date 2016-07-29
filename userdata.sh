#!/bin/bash -v

# apply security updates
yum -y install yum-fastestmirror
yum -y --security update-minimal