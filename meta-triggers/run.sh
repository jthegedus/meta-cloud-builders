#!/bin/bash

# find all *.trigger.{json,yaml} files
    # convert any yaml to json for using jq
# get the .name field of each file
# get the .name of all existing triggers
# diff the existing triggers against the .name in each file and delete
# import each of the triggers from the file list

dir=${1:-"."}
suffix=${2:-".*\.trigger\.(json|yaml)"}
workspace="./workspace/meta_triggers_tmp" # TODO: FIX THIS BEFORE TESTING FINAL VERSION!!!!!!!!!!!!!!!!!1

function has_duplicates() {
  {
    sort | uniq -d | grep . -qc
  } < "$1"
}

function cleanup() {
    rm -rf "$workspace"
}

mkdir -p "$workspace"

printf "[info] dir:\t%s\n" "$dir"
printf "[info] suffix:\t%s\n" "$suffix"

find "$dir" -type f | grep -E "$suffix" > "$workspace/trigger_configs.txt"
while read -r trigger_file; do
    # if the file is .json, convert to .yaml
    if [[ "$trigger_file" == *.json ]]; then
        yq r -j "$trigger_file" > "$workspace/temp.yaml" # write to $workspace dir to keep testing clean
        trigger_file="$workspace/temp.yaml"
    fi
    # extract 'name' field
    yq r "$trigger_file" 'name' >> "$workspace/config_trigger_names.txt"
done < "$workspace/trigger_configs.txt"

# error on duplicate filenames
if has_duplicates "$workspace/config_trigger_names.txt"; then
    triggers=$(cat "$workspace/config_trigger_names.txt")
    printf "\n[error] You have duplicate _name_ fields across Trigger configs. Names must be unique. Check your Triggers:\n\n%s" "$triggers"
    cleanup
    exit 1
fi

gcloud beta builds triggers list > "$workspace/existing_triggers.txt" # TODO: use this file to diff each proposed trigger update with the existing config to actually only update the changed ones
grep -E "^name:\s.*$" "$workspace/existing_triggers.txt" | sed -e 's/name:\s//g' > "$workspace/existing_trigger_names.txt"

printf "\n[info] existing triggers\n"
cat "$workspace/existing_trigger_names.txt"

printf "\n[info] triggers in config files\n"
cat "$workspace/config_trigger_names.txt"

printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

printf "\n[info] triggers to CREATE\n" # config NOT IN existing
comm -23 <(sort "$workspace/config_trigger_names.txt") <(sort "$workspace/existing_trigger_names.txt")
printf "\n[info] triggers to UPDATE\n" # config IN existing
comm -12 <(sort "$workspace/config_trigger_names.txt") <(sort "$workspace/existing_trigger_names.txt")
printf "\n[info] triggers to DELETE\n" # existing NOT IN config
comm -13 <(sort "$workspace/config_trigger_names.txt") <(sort "$workspace/existing_trigger_names.txt") | tee -a  "$workspace/triggers_to_delete.txt"

printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

printf "\n[info] creating & updating triggers"
while read -r line; do
    printf "\n\n%s\n" "$line"
    set -x
    gcloud beta builds triggers import --source="$line"
    set +x
done < "$workspace/trigger_configs.txt" # can use original trigger_config.txt file since there are no duplicates identified and all config files are going to be imported regardless of a CREATE or UPDATE

printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

printf "\n[info] deleting triggers"
while read -r line; do
    printf "\n\n%s\n" "$line"
    set -x
    gcloud beta builds triggers delete --quiet "$line" # TODO: use the FULLY SPECIFIED NAME for the Trigger from the CLI
    # provide the argument [trigger]
    # on the command line with a fully specified name; provide the argument
    # [--project] on the command line; set the property [core/project]. This
    # must be specified.
    set +x
done < "$workspace/triggers_to_delete.txt"

# fin
cleanup
