#!/bin/bash

found=`find "${@:1}" `;
vi $found;
