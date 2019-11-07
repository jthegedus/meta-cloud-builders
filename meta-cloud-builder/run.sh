#!/bin/bash

config_file=""
workspace_dir="./workspace/builder_repos"
timeout="${TIMEOUT:-900}"
# gcs_log_dir="${GCS_LOG_DIR:-gs//PROJECT_ID.cloudbuild-logs.googleusercontent.com/}"
# gcs_source_staging_dir="${GCS_SOURCE_STAGING_DIR:-gs//PROJECT_ID_cloudbuild/source}"

if [ $# -ne 1 ]; then
    printf "[error] missing path to config file\n"
    exit 1
fi

if [ ! -f "$1" ]; then
    printf "[error] config file %s does NOT exist\n" "$1"
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

failure_file=failure.log
touch ${failure_file}

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
            gcloud builds submit \
                --async \
                --timeout="$timeout" \
                --config "$workspace_dir/$final_path/$builder/cloudbuild.yaml" \
                "$workspace_dir/$final_path/$builder" > "$builder.log" 2>&1
                # --gcs-log-dir="$gcs_log_dir" \
                # --gcd-source-staging-dir="$gcs_source_staging_dir" \
            if [[ $? -ne 0 ]]; then
                echo "$builder failed" | tee -a ${failure_file}
                cat "$builder.log"
            fi
        done
    done


# Check if there is any failure.
if [[ -s ${failure_file} ]]; then
    printf "\nSome builds failed:\n"
    cat ${failure_file}
    printf "Exiting.\n"
    exit 1
fi

printf "All builds succeeded\n"