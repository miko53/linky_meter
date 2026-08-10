#!/bin/bash

# Check existing remotes
#git remote -v

# Add the original repository as upstream
#git remote add upstream https://github.com/miko53/linky_meter

# Fetch the latest changes from upstream
git fetch upstream

# Switch to your main branch (main or master)
git checkout master

# Merge the changes from upstream
git merge upstream/master
