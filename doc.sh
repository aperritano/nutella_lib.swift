#!/bin/bash
#######################
# Generate documentation
######################
cd iOS/Nutella
jazzy -c -o doc -a "Gianluca Venturini" -u "https://github.com/nutella-framework/nutella_lib.swift" -m "nutella_lib.swift" -g "https://github.com/nutella-framework/nutella_lib.swift" --skip-undocumented fi
