#!/bin/bash

config_file=""
workspace_dir="/workspace/builder_repos"

if [ ! -f "$1" ]; then
    printf "[error] first arg should be a config file. File %s does NOT exist\n" "$1"
    exit 1
fi

if [[ "$1" == *.yaml ]]; then
    printf "[info] converting .yaml file to .json\n"
    yq r -j "$1" > "${1%.yaml}.json"
    config_file="${1%.yaml}.json"
else
    config_file="$1"
fi

if [[ "$config_file" != *.json ]]; then
    printf "[error] invalid config file %s File must be .json or .yaml\n" "$config_file"
    exit 1
fi

printf "[info] loading from config file: %s\n" "$config_file"

# for each repo, clone to workspace
jq -r '.[] | .repo' "$config_file" | 
    while read -r url; do
        printf "[info] cloning repo %s\n" "$url"
        final_path="${url//https:\/\/github.com\//}"
        git clone "$url" "$workspace_dir/$final_path"

        # for each builder in the config for this repo, build with gcloud
        jq -r --arg repository "$url" '.[] | select(.repo == $repository) | .builders | .[]' "$config_file" |
        while read -r builder; do
            printf "\n[info] building %s\n" "$builder"
            set -x
            gcloud builds submit \
                "${@:2}" \
                --config "$workspace_dir/$final_path/$builder/cloudbuild.yaml" \
                "$workspace_dir/$final_path/$builder"
            set +x
        done
    done
