#!/bin/bash

#JQuery
wget https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js
mkdir Public/jquery
mv jquery.min.js Public/jquery

#ShowdownJS
wget https://cdnjs.cloudflare.com/ajax/libs/showdown/0.3.1/showdown.min.js
mkdir Public/showdown
mv showdown.min.js Public/showdown

#Bootstrap
wget https://github.com/twbs/bootstrap/releases/download/v3.3.1/bootstrap-3.3.1-dist.zip
unzip bootstrap-3.3.1-dist.zip
rm bootstrap-3.3.1-dist.zip
mv dist/ Public/bootstrap
