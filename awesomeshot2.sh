#!/bin/bash

version=1.2.0

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${HOME}/.config}
config_file="${XDG_CONFIG_HOME}/awesomeshot/awesomeshot.conf"

LC_ALL=C
LANG=C

LIBRARY_PATH="${PREFIX}/lib/awesomeshot"
LIBRARYS=(
    alert backupOriginalPhoto check checkConfig colors
    config convertBackground convertFooter
    convertRounded convertShadow convertTitleBar
    convertToPng handleInterruptByUser help icons notify
)

for LIBRARY in ${LIBRARYS[@]}; do
    source ${LIBRARY_PATH}/${LIBRARY}.sh
done

file_name=""

run() {
  if [ "${convert_to_png}" == "yes" ]; then
    convertToPng
  fi

  if [ "${backup}" == "yes" ]; then
    # backupOriginalPhoto "${file_name}"
    backupOriginalPhoto
  fi
    
  if [ "${convert_titlebar}" == "yes" ]; then
    convertTitleBar
    if [ "${convert_titlebar_text}" == "yes" ]; then
      convertTitleBarText
    fi
  fi

  if [ "${convert_rounded}" == "yes" ]; then
    convertRounded "to*photo"
  fi

  if [ "${convert_small_border}" == "yes" ]; then
    convertBorder "small"
  fi

  if [ "${convert_shadow}" == "yes" ]; then
    convertShadow
  fi

  if [ "${convert_background_border}" == "yes" ]; then
    convertBorder "background"
  fi

  if [ "${convert_border_gradient}" == "yes" ]; then
    convertBorderGradient "${interpolate_method}"
  fi

  if [ "${convert_footer}" == "yes" ]; then
    convertFooter
  fi

  termux-media-scan "${file_name}" &> /dev/null

  notify
}

autoRun() {
  getUserConfig

  echo -e "\n  ${COLOR_BACKGROUND_BLUE} INFO ${COLOR_RESET} Awesomeshot running on autorun, waiting to take screenshot."

  echo -e "
  ╭────────────────────────────╮
  │  ⚠ Press ${COLOR_BACKGROUND_RED} CTRL+C ${COLOR_RESET} to stop  │
  ╰────────────────────────────╯
  "

  inotifywait -m -e create ${screenshot_path} 2> /dev/null | \
    while read get_file_name_result; do
      get_file_name=$(echo -e "${get_file_name_result}" | awk '{print $3}')
      if [[ "${screenshot_path}/${get_file_name}" != "${file_name}" || -z ${file_name} ]]; then

        # Fix bug screenshot filename ".pending" 
        if [ ${get_file_name%%-*} == ".pending" ]; then
          file_name="${screenshot_path}/${get_file_name##*-}"
        else
          file_name="${screenshot_path}/${get_file_name}"
        fi

        sleep 1.5s

        run

        if [ "${open_image}" == "yes" ]; then
          termux-open "${file_name}"
        fi

        echo -e ""
      fi
    done
}

main() {
  trap "handleInterruptByUser 'Interrupt By User'" 2
  ${1} ${2}
}

version() {
    echo -e "awesomeshot v.${version}"
}

case "${1}" in
  -a|--auto )
    main autoRun
  ;;
  -c|--config )
    generateDefaultConfig
  ;;
  -m|--manual )
    if [ ${2} ]; then
      file_name="${2}"
      main manualRun
    else
      logError "error" "This option require filename"
      exit 1
    fi
  ;;
  -h|--help )
    help
  ;;
  -v|--version )
    version
  ;;
  *)
    help
  ;;
esac