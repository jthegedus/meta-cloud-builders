#!/bin/bash

test="a"

printf "testing %s" $test

if [[ $test -eq 'a' ]]; then
    echo $test
fi