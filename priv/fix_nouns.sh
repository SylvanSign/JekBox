#!/bin/bash

tr a-z A-Z < nouns.txt | sort | uniq > nouns2.txt ; mv nouns2.txt nouns.txt
