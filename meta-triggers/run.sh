#!/bin/bash

# find all *.trigger.{json,yaml} files in dir
# diff the existing triggers against the triggers defined in the config file
# create/update triggers in config files
# delete triggers in project no longer in config files

dir=${1:-"."}
suffix=${2:-".*\.trigger\.(json|yaml)"}
tmp_workspace="/workspace/meta_triggers_tmp"

function has_duplicates() {
	{
		sort | uniq -d | grep . -qc
	} <"$1"
}

function cleanup() {
	rm -rf "$tmp_workspace"
}

mkdir -p "$tmp_workspace"

printf "[info] dir:\t%s\n" "$dir"
printf "[info] suffix:\t%s\n" "$suffix"

# read trigger names into a file
find "$dir" -type f | grep -E "$suffix" >"$tmp_workspace/trigger_configs.txt"
while read -r trigger_file; do
	if [[ "$trigger_file" == *.json ]]; then
		# json
		jq -r '.name' "$trigger_file" >>"$tmp_workspace/config_trigger_names.txt"
	else
		# yaml
		yq r "$trigger_file" 'name' >>"$tmp_workspace/config_trigger_names.txt"
	fi
done <"$tmp_workspace/trigger_configs.txt"

# error on duplicate trigger names
if has_duplicates "$tmp_workspace/config_trigger_names.txt"; then
	triggers=$(cat "$tmp_workspace/config_trigger_names.txt")
	printf "\n[error] You have duplicate _name_ fields across Trigger configs. Names must be unique. Check your Triggers:\n\n%s" "$triggers"
	cleanup
	exit 1
fi

gcloud beta builds triggers list >"$tmp_workspace/existing_triggers.yaml" # TODO: use this file to diff each proposed trigger update with the existing config to actually only update the changed ones
grep -E "^name:\s.*$" "$tmp_workspace/existing_triggers.yaml" | sed -e 's/name:\s//g' >"$tmp_workspace/existing_trigger_names.txt"

printf "\n[info] existing triggers\n"
cat "$tmp_workspace/existing_trigger_names.txt"

printf "\n[info] triggers in config files\n"
cat "$tmp_workspace/config_trigger_names.txt"

printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

printf "\n[info] triggers to CREATE\n" # config NOT IN existing
comm -23 <(sort "$tmp_workspace/config_trigger_names.txt") <(sort "$tmp_workspace/existing_trigger_names.txt")
printf "\n[info] triggers to UPDATE\n" # config IN existing
comm -12 <(sort "$tmp_workspace/config_trigger_names.txt") <(sort "$tmp_workspace/existing_trigger_names.txt")
printf "\n[info] triggers to DELETE\n" # existing NOT IN config
comm -13 <(sort "$tmp_workspace/config_trigger_names.txt") <(sort "$tmp_workspace/existing_trigger_names.txt") | tee -a "$tmp_workspace/triggers_to_delete.txt"

printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

printf "\n[info] creating & updating triggers"
while read -r line; do
	set -x
	gcloud beta builds triggers import --source="$line"
	set +x
done <"$tmp_workspace/trigger_configs.txt" # can use original trigger_configs.txt file since there are no duplicates identified and all config files are going to be imported regardless of a CREATE or UPDATE

printf "\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"

printf "\n[info] deleting triggers"
while read -r trigger_name; do
	yq r -d'*' -j "$tmp_workspace/existing_triggers.yaml" >"$tmp_workspace/existing_triggers.json"
	trigger_id=$(jq -r --arg trigger_name "$trigger_name" '.[] | select(.name == $trigger_name) | .id' "$tmp_workspace/existing_triggers.json")
	set -x
	gcloud beta builds triggers delete --quiet "$trigger_id"
	set +x
done <"$tmp_workspace/triggers_to_delete.txt"

# fin
cleanup
