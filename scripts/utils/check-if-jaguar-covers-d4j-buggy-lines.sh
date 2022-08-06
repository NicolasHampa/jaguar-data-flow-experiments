#! /bin/bash
#
# For a given Jaguar dataset, checks for which D4J projects versions
# the spectra files covers the buggy or candidates lines 
#

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

            IFS='/' read -ra project_version_path_array <<< "$d4j_project_version_path"
            index=${#project_version_path_array[@]}
            project_name=${project_version_path_array[((index-2))]}
            project_version=${project_version_path_array[((index-1))]}
            
            jaguar_spectra_version_path=$d4j_project_version_path"/jaguar/.jaguar/spectra"
            for spectra_file_path in `find $jaguar_spectra_version_path -maxdepth 1 -mindepth 1 -type f`
            do
                JAGUAR_LINES_FILE=/tmp/"$project_name"-"$project_version"-lines.txt
                python map-duas-to-lines.py --class_duas_file "$spectra_file_path" \
                    --output "$JAGUAR_LINES_FILE"
            done

            all_jaguar_lines=()
            while read line; do
                all_jaguar_lines+=($line)
            done < $JAGUAR_LINES_FILE

            echo $project_name" / "$project_version >> "$HOME/d4j-$project_name-buggy-lines-not-covered-by-jaguar.txt"

            covers_at_least_one_buggy_line=0
            while read buggy_line; do
                IFS='#' read -ra line_array <<< "$buggy_line"
                buggy_line=${line_array[((0))]}"#"${line_array[((1))]}
                faulty_code=${line_array[(2)]}

                if [ "$faulty_code" == "FAULT_OF_OMISSION" ]; then                    
                    bug_covered=0
                    while read candidate_line; do
                        IFS=',' read -ra candidate_array <<< "$candidate_line"
                        candidate_line=${candidate_array[((1))]}
                        if [ "$buggy_line" == "${candidate_array[((0))]}" ]; then
                            if [[ "${all_jaguar_lines[*]}" =~ "${candidate_line}" ]]; then
                                bug_covered=1
                                break
                            fi 
                        fi
                    done < ../score-ranking/buggy-lines/$project_name"-"${project_version%"b"}".candidates"

                    if [ "$bug_covered" == 0 ]; then
                        while read source_code_line; do
                            IFS=':' read -ra source_code_line_array <<< "$source_code_line"
                            key_line=${source_code_line_array[((0))]}
                            entry_line=${source_code_line_array[((1))]}
                            echo $key_line
                        done < "/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/source-code-lines/"$project_name"-"$project_version".source-code.lines"
                    else
                        covers_at_least_one_buggy_line=1
                    fi
                else
                    if [[ ! "${all_jaguar_lines[*]}" =~ "${buggy_line}" ]]; then
                        while read source_code_line; do
                            IFS=':' read -ra source_code_line_array <<< "$source_code_line"
                            key_line=${source_code_line_array[((0))]}
                            entry_line=${source_code_line_array[((1))]}

                            if [ "$buggy_line" == "$entry_line" ]; then
                                if [[ "${all_jaguar_lines[*]}" =~ "${key_line}" ]]; then
                                    covers_at_least_one_buggy_line=1
                                    break
                                fi
                            fi
                        done < "/home/nicolas/GitRepo/jaguar-data-flow-experiments/scripts/score-ranking/source-code-lines/"$project_name"-"$project_version".source-code.lines"
                    else
                        covers_at_least_one_buggy_line=1
                    fi
                fi
            done < ../score-ranking/buggy-lines/$project_name"-"${project_version%"b"}".buggy.lines"

            if [ "$covers_at_least_one_buggy_line" == 0 ]; then
                echo "[WARNING] None of the buggy or candidates lines has been covered by Jaguar!" >> "$HOME/d4j-$project_name-buggy-lines-not-covered-by-jaguar.txt"
            fi

            rm -rf $JAGUAR_LINES_FILE
        fi
    done
done
