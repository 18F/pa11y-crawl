#! /usr/bin/env bash

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
reset=`tput sgr0`

type jq >/dev/null 2>&1 || {
  echo "${red}x${reset} pa11y-crawl relies on jq to edit JSON files"
  echo "Please install jq: https://stedolan.github.io/jq/download/"
  exit 1
}

type pa11y >/dev/null 2>&1 || {
  echo "${red}x${reset} pa11y not found"
  echo "${blue}|${reset} attempting to install"
  npm install -g pa11y pa11y-reporter-full-json >/dev/null
}

usage(){
  echo "Usage: pa11y-crawl [options] <URL>"
  echo ""
  echo "Options:"
  echo "  -d, --directory       use an existing local directory instead of wget"
  echo "  -c, --continua11y     set continua11y URL (default: continua11y.18f.gov)"
  echo "  -h, --help            show this help message and exit"
  echo "  -i, --ci              continuous integration mode; incorporates repo metadata"
  echo "                          and sends a report to continua11y"
  echo "  -m, --sitemap         use the site's sitemap.xml to find pages, rather than wget spider"
  echo "  -o, --output          set output file for report (default: ./results.json)"
  echo "  -p, --parallel        the number of parallel processes to run (default: 1)"
  echo "  -q, --quiet           quiet mode"
  echo "  -r, --run             pass a command to start a local server for analysis"
  echo "  -s, --standard        set accessibility standard "
  echo "                          (Section508, WCAG2A, WCAG2AA (default), WCAG2AAA)"
  echo "  -t, --temp-dir        set location for storing temporary files (default: ./temp)"
  echo "  -v, --version         show program version and exit"
}

version(){
  VERSION=$(cat package.json | jq '.version' | tr -d '"')
  echo $VERSION
}

relpath() {
    python -c 'import sys, os.path; print os.path.relpath(sys.argv[1], sys.argv[2])' "$1" "${2:-$PWD}";
}


# set default values
CONTINUA11Y_URL="https://continua11y.18f.gov/incoming"
OUTPUT=$(pwd)/results.json
TEMP_DIR=$(pwd)/pa11y-crawl
STANDARD="WCAG2AA"
PARALLEL=false

# Convert known long options to short options
for arg in "$@"; do
  shift
  case "$arg" in
    --help)
      set -- "$@" "-h"
      ;;
    --version)
      set -- "$@" "-v"
      ;;
    --quiet)
      set -- "$@" "-q"
      ;;
    --output)
      set -- "$@" "-o"
      ;;
    --standard)
      set -- "$@" "-s"
      ;;
    --ci)
      set -- "$@" "-i"
      ;;
    --continua11y)
      set -- "$@" "-c"
      ;;
    --sitemap)
      set -- "$@" "-m"
      ;;
    --temporary)
      set -- "$@" "-t"
      ;;
    --directory)
      set -- "$@" "-d"
      ;;
    --run)
      set -- "$@" "-r"
      ;;
    --parallel)
      set -- "$@" "-p"
      ;;
    *)
      set -- "$@" "$arg"
      ;;
  esac
done

# Reset to beginning of arguments
OPTIND=1

# Process option flags
while getopts "hvmqp:o:s:it:c:d:r:" opt; do
  case $opt in
    h )
      usage
      exit 0
      ;;
    v )
      version
      exit 0
      ;;
    q )
      exec 1>/dev/null 2>/dev/null
      ;;
    o )
      OUTPUT="$OPTARG"
      ;;
    s )
      STANDARD="$OPTARG"
      ;;
    i )
      CI=true
      ;;
    c )
      CONTINUA11Y_URL="$OPTARG"
      ;;
    m )
      USE_SITEMAP=true
      ;;
    t )
      TEMP_DIR="$OPTARG"
      ;;
    d )
      TARGET_DIR="$OPTARG"
      ;;
    r )
      RUN_COMMAND="$OPTARG"
      ;;
    p )
      # TODO: check that this is a number
      if [[ ! $OPTARG =~ ^[0-9]+$ ]]; then
        echo "Invalid argument for --parallel: ${OPTARG}"
        echo "Please enter a number instead"
        exit 1
      fi
      PARALLEL="$OPTARG"
      ;;
    * )
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# show help if run without arguments
if [ $# -ne 1 ]; then
  usage
  exit 0
fi

TARGET=$1

# clean out temporary directory
mkdir -p $TEMP_DIR
rm -rf $TEMP_DIR/*

# get the most recent git commit message
COMMIT_MSG="$(git log --format=%B --no-merges -n 1 | sed s/\"/\'/g)"

# prepare data for JSON
if [[ "$CI" = true ]]; then
  if [[ "$TRAVIS" = true ]]; then
    echo "${green} >>> ${reset} detected travis-ci; grabbing information"
    REPO_SLUG=$TRAVIS_REPO_SLUG
    BRANCH=$TRAVIS_BRANCH
    COMMIT=$TRAVIS_COMMIT
    PULL_REQUEST=$TRAVIS_PULL_REQUEST
    COMMIT_RANGE=$TRAVIS_COMMIT_RANGE
  else
    echo "${green} >>> ${reset} running on unknown ci; building information"
    REPO_SLUG=$(git remote show $(git remote show) | grep Push | cut -d' ' -f6 | sed -e 's/\.git//' -e 's/git@.*\..*://' -e 's/https:\/\/.*\.[[:alpha:]]*\///')
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    COMMIT=$(git log --format=%H --no-merges -n 1)
    PULL_REQUEST=false # unsure how to check this in git
    COMMIT_RANGE="abcd123..jklm789"
  fi
  # set up the JSON file for full results to send
  echo '{"repository":"'$REPO_SLUG'", "branch": "'$BRANCH'","commit":"'$COMMIT'","commit_message":"'$COMMIT_MSG'","pull_request":"'$PULL_REQUEST'","commit_range":"'$COMMIT_RANGE'","standard":"'$STANDARD'","data":{}}' | jq '.' > $OUTPUT
else
  # for non-ci environment, a simpler JSON file will do just fine
  echo '{"data":{}}' | jq '.' > $OUTPUT
fi

if [[ $RUN_COMMAND ]]; then
  echo "${green} >>> ${reset} starting server using \"${RUN_COMMAND}\""
  eval $RUN_COMMAND >/dev/null 2>&1 &
  PID=$!
  sleep 5
fi

if [[ $TARGET_DIR ]]; then
  # move to the target directory with the site files
  cd $TARGET_DIR
else
  cd $TEMP_DIR
  # make local copy of the site using wget
  if [[ "$USE_SITEMAP" = true ]]; then
      echo "${green} >>> ${reset} using sitemap to mirror relevant portion of site"
      curl --silent $TARGET/sitemap.xml | grep "<loc>" | sed 's/[^>]*>\([^<]*\).*/\1/' > $TEMP_DIR/sites.txt
      if [[ "$PARALLEL" != false ]]; then
        cat $TEMP_DIR/sites.txt | xargs -P $PARALLEL -I _url_ sh -c 'save=${1#h*//*/}; save=${save%/}; save=${save//\//-\\-}.html; wget $1 -O $save' -- _url_
      else
        cat $TEMP_DIR/sites.txt | while read a; do save=${a#h*//*/} && save=${save%/} && save=${save//\//\\} && wget $a -O "${save}.html"; done
      fi
      rm $TEMP_DIR/sites.txt
  else
      echo "${green} >>> ${reset} using wget to mirror site"
      wget --adjust-extension --quiet --mirror --convert-links --header="Accept: text/*" $TARGET
  fi
fi

echo "${green} <<< ${reset} found $(find . -type f | wc -l | sed 's/^ *//;s/ *$//') files in $(find . -mindepth 1 -type d | wc -l | sed 's/^ *//;s/ *$//') directories"

# iterate through URLs and run runtest on each
function runtest () {
    URL="$(relpath $file .)"
    FILE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
    if [[ $(file -b --mime-type $file) == "text/html" ]]
    then
        echo "${blue} |--------------------------------------- ${reset}"
        echo "${blue} |-> ${reset} analyzing ${URL}"
        if [[ $TARGET_DIR ]]; then
          pa11y -r full-json -s $STANDARD file:///$FILE > $TEMP_DIR/pa11y.json
        else
          # ideally, this should run on the file, as well, but that seems to be error-prone
          pa11y -r full-json -s $STANDARD $URL > $TEMP_DIR/pa11y.json
        fi

        # add this report into results.json
        jq -s '.[0] * {data: {(.[1].url): .[1]}}' $OUTPUT $TEMP_DIR/pa11y.json > $TEMP_DIR/temp.json
        cp $TEMP_DIR/temp.json $OUTPUT
        ERROR="$(cat $TEMP_DIR/pa11y.json | jq .count.error)"
        WARNING="$(cat $TEMP_DIR/pa11y.json | jq .count.warning)"
        NOTICE="$(cat $TEMP_DIR/pa11y.json | jq .count.notice)"
        echo "${green} <<< ${reset} pa11y says: ${red}error:${reset} ${ERROR} | ${yellow}warning:${reset} ${WARNING} | ${green}notice:${reset} ${NOTICE}"
        rm $TEMP_DIR/pa11y.json
    else
        echo "${blue} ||  ${reset} ${URL} is not an html document, skipping"
    fi
}

echo "${green} >>> ${reset} beginning the analysis"
echo "${blue} |--------------------------------------- ${reset}"
if [[ "$PARALLEL" != false ]]; then
  echo "${green} >>> ${reset} running pa11y in parallel"
  find . | xargs -P $PARALLEL -I _url_ sh -c 'if [[ $(file -b --mime-type $1) == "text/html" ]]; then save=${1#h*//*/}; save=${save%/}; save=${save//\//-\\-}.json; pa11y -r full-json ${1:2} > $save; fi' -- _url_
  echo "${green} >>> ${reset} consolidating files"
  for file in $(find $TEMP_DIR -name '*.json'); do
    jq -s '.[0] * {data: {(.[1].url): .[1]}}' $OUTPUT $file > $TEMP_DIR/temp.json
    mv $TEMP_DIR/temp.json $OUTPUT
  done
else
  for file in $(find .);
  do
      runtest $file
  done
fi

if [[ $CI ]]; then
    echo "${green} >>> ${reset} sending data to continua11y"
    curl -s -X POST $CONTINUA11Y_URL -H "Content-Type: application/json" -d @$OUTPUT -o /dev/null 2>&1
fi

# clean up
echo "${green} >>> ${reset} cleaning up"
rm -rf $TEMP_DIR
if [[ $RUN_COMMAND ]]; then
  kill $PID >/dev/null 2>&1
fi
