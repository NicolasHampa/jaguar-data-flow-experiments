#! /bin/bash

if [ -z "$1" ] ; then
    echo "Repository root path is missing! Execution has been stopped."
    exit 1
fi

if [ -z "$2" ] ; then
    echo "Coverage tool [gzoltar,jaguar] is missing! Execution has been stopped."
    exit 1
fi

if [ -z "$3" ] ; then
    echo "Analysis type [sbfl,mlfl,all] is missing! Execution has been stopped."
    exit 1
fi

logs=0
while getopts 'l' OPTION; do
  case "$OPTION" in
    l)
      echo "logging enabled!"
      logs=1
      ;;
    ?)
      echo "script usage: [-l]" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

repository_root_path=$1
coverage_tool=$2
analysis_type=$3

for project_path in `find $repository_root_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        IFS='/' read -ra project_version_path_array <<< "$project_version_path"
        index=${#project_version_path_array[@]}
        project_name=${project_version_path_array[((index-2))]}
        project_version=${project_version_path_array[((index-1))]}

        if [ ${coverage_tool} == "gzoltar" ]; then
            ./do-full-analysis $project_name $project_version $project_version_path/matrix $project_version_path/spectra gzoltar $analysis_type $logs ../../reports/
        fi

        if [ ${coverage_tool} == "jaguar" ] && [ "${project_version: -1}" == "b" ]; then
            project_version=${project_version%"b"}
            ./do-full-analysis-dua $project_name $project_version $project_version_path jaguar $analysis_type $logs ../../reports/
        fi
    done
done