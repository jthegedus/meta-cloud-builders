#!/usr/bin/env bash

set -eo pipefail
IFS=$'\n\t'

# find all *.trigger.{json,yaml} files in dir
# filter triggers for those that target the executing project
# diff the existing triggers against the triggers defined in the config file
# upsert triggers from config files
# delete triggers in project no longer in config files
: "${TARGET_PROJECT_ID:?Env var TARGET_PROJECT_ID is required and should be set to $PROJECT_ID in Cloud Build. Pass it to the builder via the env: list. See env usage here: https://cloud.google.com/cloud-build/docs/build-config#build_steps}"
dir=${TRIGGERS_DIRECTORY:-"."}
suffix=${TRIGGERS_SUFFIX:-".*\.trigger\.(json|yaml|yml)"}
development_testing=${DEVELOPMENT_TESTING:-"false"}

function log_info() {
	printf "[info]\\t%s\\n" "${@}"
}

function log_error() {
	printf "[error]\\t%s\\n" "${@}"
}

# params:
# 	bash array
# returns:
# 	0 if duplicates
# 	1 if no duplicates
function array_has_duplicates() {
	{
		# grep is used to return 0 if uniq -d returns a list of values. Credit https://stackoverflow.com/a/22499126/7911479
		local arr=("$@")
		printf "%s\n" "${arr[@]}" | uniq -d | grep . -qc
	}
}

# params:
# 	path and filename of file
# returns:
# 	0 if  match for the current $TARGET_PROJECT_ID
# 	1 if no match
function trigger_targets_current_project() {
	{
		# grep is used to return 0 if yq returns a list of values. Credit https://stackoverflow.com/a/22499126/7911479
		yq r "${1}" "projects.(.==$TARGET_PROJECT_ID)" | grep . -qc
	}
}

function main() {
	log_info "dir:\\t$dir"
	log_info "suffix:\\t$suffix"
	log_info "target project:\\t$TARGET_PROJECT_ID"

	# read trigger names from source code
	local trigger_files_all=()
	local trigger_files_project_match=()
	local trigger_names_project_match=()
	local trigger_names_project_mismatch=()

	local existing_trigger_names=()
	local create_trigger_names=()
	local update_trigger_names=()
	local delete_trigger_names=()

	trigger_files_all+=($(find "$dir" -type f | grep -E "$suffix"))
	if [[ "${#trigger_files_all[@]}" -eq 0 ]]; then
		log_info "No Cloud Build triggers found in dir $dir matching file suffix $suffix"
	fi

	# for each of the matching trigger files
	# 	check the trigger targets this project
	# 	track the trigger name
	# 	track the file path of the trigger
	# 	inline remove the 'projects' array from the trigger to avoid this issue https://issuetracker.google.com/issues/158379523
	for trigger_file in "${trigger_files_all[@]}"; do
		if trigger_targets_current_project "$trigger_file"; then
			trigger_names_project_match+=($(yq r "$trigger_file" 'name'))
			trigger_files_project_match+=("$trigger_file")
			yq d -i "$trigger_file" 'projects'
		else
			trigger_names_project_mismatch+=($(yq r "$trigger_file" 'name'))
		fi
	done

	# error on duplicate trigger names
	if array_has_duplicates "${trigger_names_project_match[@]}"; then
		log_error "You have duplicate _name_ fields across Trigger configs. Names must be unique. Check your Triggers:"
		log_error "${trigger_names_project_match[@]}"
		cleanup
		exit 1
	fi

	# use gcloud to get existing trigger names
	existing_trigger_names=($(gcloud beta builds triggers list | yq r -d'*' - 'name'))
	# in source ! in existing
	create_trigger_names+=($(comm -23 <(printf "%s\n" "${trigger_names_project_match[@]}" | sort) <(printf "%s\n" "${existing_trigger_names[@]}" | sort)))
	# in source & in existing
	update_trigger_names+=($(comm -12 <(printf "%s\n" "${trigger_names_project_match[@]}" | sort) <(printf "%s\n" "${existing_trigger_names[@]}" | sort)))
	# ! in source & in existing
	delete_trigger_names+=($(comm -13 <(printf "%s\n" "${trigger_names_project_match[@]}" | sort) <(printf "%s\n" "${existing_trigger_names[@]}" | sort)))

	log_info "-----Triggers in source code-----"
	log_info "Triggers INCLUDED because of project match"
	log_info "${trigger_names_project_match[@]}"

	log_info "Triggers IGNORED because of project mismatch"
	log_info "${trigger_names_project_mismatch[@]}"

	log_info "-----Existing Triggers in project-----"
	log_info "${existing_trigger_names[@]}"

	log_info "Triggres to CREATE"
	log_info "${create_trigger_names[@]}"

	log_info "Triggers to UPDATE"
	log_info "${update_trigger_names[@]}"

	log_info "Triggers to DELETE"
	log_info "${delete_trigger_names[@]}"

	if [[ "$development_testing" == "true" ]]; then
		log_info "In development mode. Triggers will not be Upserted or Deleted."
		for trigger_file in "${trigger_files_project_match[@]}"; do
			log_info "Trigger to update: $trigger_file"
		done
		for trigger_name in "${delete_trigger_names[@]}"; do
			log_info "Trigger to delete: $trigger_name"
		done
		exit 0
	fi

	log_info "Upserting Triggers"
	# since this is an upsert we just apply all trigger configs from the source code that target this project
	for trigger_file in "${trigger_files_project_match[@]}"; do
		set -x
		gcloud beta builds triggers import --source="$trigger_file"
		set +x
	done

	log_info "Deleting Triggers"
	for trigger_name in "${delete_trigger_names[@]}"; do
		set -x
		gcloud beta builds triggers delete --quiet "${trigger_name}"
		set +x
	done
	log_info "Finished syncing Cloud Build Triggers into project $TARGET_PROJECT_ID"
}

main
