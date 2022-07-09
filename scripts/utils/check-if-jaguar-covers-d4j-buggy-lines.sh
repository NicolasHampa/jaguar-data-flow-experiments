#! /bin/bash

if [ -z "$1" ] ; then
    echo "Path containing Jaguar data for D4J programs is missing! Execution has been stopped."
    exit 1
fi

jaguar_data_path=$1

for d4j_project_path in `find $jaguar_data_path -maxdepth 1 -mindepth 1 -type d`
do
    for d4j_project_version_path in `find $d4j_project_path -maxdepth 1 -mindepth 1 -type d`
    do
        if [ "${d4j_project_version_path: -1}" == "b" ]; then
            
            jaguar_spectra_version_path=$d4j_project_version_path"/jaguar/.jaguar/spectra"
            jaguar_spectra_files=()
            for spectra_file_path in `find $jaguar_spectra_version_path -maxdepth 1 -mindepth 1 -type f`
            do
                IFS='/' read -ra spectra_filename_array <<< "$spectra_file_path"
                index=${#spectra_filename_array[@]}
                spectra_filename=${spectra_filename_array[((index-1))]}
                spectra_filename=${spectra_filename%".spectra"}

                IFS='.' read -ra spectra_filename_array <<< "$spectra_filename"
                index=${#spectra_filename_array[@]}
                spectra_filename=${spectra_filename_array[((index-1))]}

                if [[ ! " ${jaguar_spectra_files[*]} " =~ " ${spectra_filename} " ]]; then
                    jaguar_spectra_files+=($spectra_filename)
                fi
            done

            IFS='/' read -ra project_version_path_array <<< "$d4j_project_version_path"
            index=${#project_version_path_array[@]}
            project_name=${project_version_path_array[((index-2))]}
            project_version=${project_version_path_array[((index-1))]}

            echo $project_name"/"$project_version

            classes=()
            while read line; do
                IFS='#' read -ra line_array <<< "$line"
                clazz=${line_array[((0))]}

                IFS='$' read -ra clazz_array  <<< "$clazz"
                clazz=${clazz_array[((0))]}

                IFS='/' read -ra clazz_array <<< "$clazz"
                index=${#clazz_array[@]}
                clazz=${clazz_array[((index-1))]}

                clazz=${clazz%".java"}

                if [[ ! " ${classes[*]} " =~ " ${clazz} " ]]; then
                    classes+=($clazz)
                else 
                    continue
                fi

                echo "Jaguar covered class " $clazz " ?"

                if [[ " ${jaguar_spectra_files[*]} " =~ " ${clazz} " ]]; then
                    echo "Yes"
                else
                    echo "No"
                fi 
            done < ../score-ranking/buggy-lines/$project_name"-"${project_version%"b"}".buggy.lines"
            echo
        fi
    done
done
