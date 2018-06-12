#!/usr/bin/env bash
#
# A simple, configurable HTTP server written in bash.
#
# See LICENSE for licensing information.
#
# Original author: Avleen Vig, 2012
# Reworked by:     Josh Cartwright, 2012
# Reworked by:     Nathan Rajlich, 2018

# If running as `root`, then downgrade to `nobody` first
if [ "$EUID" -eq 0 ]; then
  exec sudo -u nobody "$0" "$@"
fi

conf="${BASHTTPD_CONFIG-bashttpd.conf}"

[ -r "${conf}" ] || {
   cat > "${conf}" <<'EOF'
#
# bashttpd.conf - configuration for bashttpd
#
# The behavior of bashttpd is dictated by the evaluation
# of rules specified in this configuration file.  Each rule
# is evaluated until one is matched.  If no rule is matched,
# bashttpd will serve a 500 Internal Server Error.
#
# The format of the rules are:
#    on_uri_match REGEX command [args]
#    unconditionally command [args]
#
# on_uri_match:
#   On an incoming request, the URI is checked against the specified
#   (bash-supported extended) regular expression, and if encounters a match the
#   specified command is executed with the specified arguments.
#
#   For additional flexibility, on_uri_match will also pass the results of the
#   regular expression match, ${BASH_REMATCH[@]} as additional arguments to the
#   command.
#
# unconditionally:
#   Always serve via the specified command.  Useful for catchall rules.
#
# The following commands are available for use:
#
#   serve_file FILE
#     Statically serves a single file.
#
#   serve_dir_with_tree DIRECTORY
#     Statically serves the specified directory using 'tree'.  It must be
#     installed and in the PATH.
#
#   serve_dir_with_ls DIRECTORY
#     Statically serves the specified directory using 'ls -al'.
#
#   serve_dir  DIRECTORY
#     Statically serves a single directory listing.  Will use 'tree' if it is
#     installed and in the PATH, otherwise, 'ls -al'
#
#   serve_dir_or_file_from DIRECTORY
#     Serves either a directory listing (using serve_dir) or a file (using
#     serve_file).  Constructs local path by appending the specified root
#     directory, and the URI portion of the client request.
#
#   serve_static_string STRING
#     Serves the specified static string with Content-Type text/plain.
#
# Examples of rules:
#
# on_uri_match '^/issue$' serve_file "/etc/issue"
#
#   When a client's requested URI matches the string '/issue', serve them the
#   contents of /etc/issue
#
# on_uri_match 'root' serve_dir /
#
#   When a client's requested URI has the word 'root' in it, serve up
#   a directory listing of /
#
# DOCROOT=/var/www/html
# on_uri_match '/(.*)' serve_dir_or_file_from "$DOCROOT"
#   When any URI request is made, attempt to serve a directory listing
#   or file content based on the request URI, by mapping URI's to local
#   paths relative to the specified "$DOCROOT"
#

unconditionally serve_static_string 'Hello, world!  You can configure bashttpd by modifying bashttpd.conf.'

# More about commands:
#
# It is possible to somewhat easily write your own commands.  An example
# may help.  The following example will serve "Hello, $x!" whenever
# a client sends a request with the URI /say_hello_to/$x:
#
# serve_hello() {
#    set_response_header "Content-Type" "text/plain"
#    echo "Hello, $2!"
# }
# on_uri_match '^/say_hello_to/(.*)$' serve_hello
#
# Like mentioned before, the contents of ${BASH_REMATCH[@]} are passed
# to your command, so its possible to use regular expression groups
# to pull out info.
#
# With this example, when the requested URI is /say_hello_to/Josh, serve_hello
# is invoked with the arguments '/say_hello_to/Josh' 'Josh',
# (${BASH_REMATCH[0]} is always the full match)
EOF
   echo "Created bashttpd.conf using defaults."
   echo "Please review it/configure before running bashttpd again."
   exit 1
}

recv() { echo "<" "$@" >&2; }
send() { echo ">" "$@" >&2;
         printf "%s\r\n" "$*"; }

read_bytes() {
  LANG=C IFS= read -r -d '' -n "$1" char
  printf "%s" "${char}"
}

DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
      "Date: $DATE"
   "Expires: $DATE"
    "Server: Slash Bin Slash Bash"
)

add_response_header() {
   RESPONSE_HEADERS+=("$1: $2")
}

_add_response_header() {
   RESPONSE_HEADERS+=("$1")
}

declare -a HTTP_RESPONSE=(
  [100]="Continue"
  [101]="Switching Protocols"
  [102]="Processing"
  [103]="Early Hints"
  [200]="OK"
  [201]="Created"
  [202]="Accepted"
  [203]="Non-Authoritative Information"
  [204]="No Content"
  [205]="Reset Content"
  [206]="Partial Content"
  [207]="Multi-Status"
  [208]="Already Reported"
  [226]="IM Used"
  [300]="Multiple Choices"
  [301]="Moved Permanently"
  [302]="Found"
  [303]="See Other"
  [304]="Not Modified"
  [305]="Use Proxy"
  [307]="Temporary Redirect"
  [308]="Permanent Redirect"
  [400]="Bad Request"
  [401]="Unauthorized"
  [402]="Payment Required"
  [403]="Forbidden"
  [404]="Not Found"
  [405]="Method Not Allowed"
  [406]="Not Acceptable"
  [407]="Proxy Authentication Required"
  [408]="Request Timeout"
  [409]="Conflict"
  [410]="Gone"
  [411]="Length Required"
  [412]="Precondition Failed"
  [413]="Payload Too Large"
  [414]="URI Too Long"
  [415]="Unsupported Media Type"
  [416]="Range Not Satisfiable"
  [417]="Expectation Failed"
  [418]="I'm a teapot"
  [421]="Misdirected Request"
  [422]="Unprocessable Entity"
  [423]="Locked"
  [424]="Failed Dependency"
  [425]="Unordered Collection"
  [426]="Upgrade Required"
  [428]="Precondition Required"
  [429]="Too Many Requests"
  [431]="Request Header Fields Too Large"
  [451]="Unavailable For Legal Reasons"
  [500]="Internal Server Error"
  [501]="Not Implemented"
  [502]="Bad Gateway"
  [503]="Service Unavailable"
  [504]="Gateway Timeout"
  [505]="HTTP Version Not Supported"
  [506]="Variant Also Negotiates"
  [507]="Insufficient Storage"
  [508]="Loop Detected"
  [509]="Bandwidth Limit Exceeded"
  [510]="Not Extended"
  [511]="Network Authentication Required"
)

send_response_header() {
   local code=$1
   send "HTTP/1.0 ${code} ${HTTP_RESPONSE[${code}]}"
   for i in "${RESPONSE_HEADERS[@]}"; do
      send "$i"
   done
   send
}

_fail_with() {
   send_response_header "$1"
   echo "$1 ${HTTP_RESPONSE[$1]}"
   exit 1
}

# Request-Line HTTP RFC 2616 $5.1
IFS='' read -r line || _fail_with 400

# strip trailing CR if it exists
line=${line%%$'\r'}
recv "$line"

read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<<"$line"

[ -n "$REQUEST_METHOD" ] && \
[ -n "$REQUEST_URI" ] && \
[ -n "$REQUEST_HTTP_VERSION" ] \
   || _fail_with 400

REQUEST_PATH="${REQUEST_URI%%\?*}"
QUERY_STRING="${REQUEST_URI#*\?}"

declare -a REQUEST_HEADERS

while IFS='' read -r line; do
   line=${line%%$'\r'}
   recv "$line"

   # If we've reached the end of the headers, break.
   [ -z "$line" ] && break

   REQUEST_HEADERS+=("$line")
done

CONTROL_SEQUENCE=$'\1'

flush_response() {
  # Wait for response code and header "events" from stdin
  local code=200
  local buf
  while true; do
    local buf="$(read_bytes "${#CONTROL_SEQUENCE}")"
    #recv "buf: $(printf "%x " "'${buf}") ${#buf}"
    if [ "${buf}" = "${CONTROL_SEQUENCE}" ]; then
      IFS='' read -r line
      line=${line%%$'\r'}
      #recv "line: ${line}"
      local cmd="${line:0:1}"
      local data="${line:1}"
      case "${cmd}" in
        C) code="${data}";;
        H) _add_response_header "${data}";;
      esac
    else
      break
    fi
  done
  send_response_header "${code}"
  printf "%s" "${buf}"
  cat
}

# Set the response status code.
# MUST be called *before* any output is generated by your script.
set_response_code() {
  echo "${CONTROL_SEQUENCE}C$1"
}

# Sets a response header.
# MUST be called *before* any output is generated by your script.
set_response_header() {
  local header="$1"
  shift
  if [ $# -ne 0 ]; then
    header="${header}: $*"
  fi
  echo "${CONTROL_SEQUENCE}H${header}"
}

fail_with() {
  set_response_code "$1"
  echo "$1 ${HTTP_RESPONSE[$1]}"
  return 1
}

serve_file() {
  local file="$1"
  local length="$(stat -c'%s' "$file")"
  if [ $? -ne 0 ]; then
    fail_with 404
  else
    CONTENT_TYPE=
    case "$file" in
      *\.css)
        CONTENT_TYPE="text/css"
        ;;
      *\.js)
        CONTENT_TYPE="text/javascript"
        ;;
      *)
        CONTENT_TYPE="$(file -b --mime-type "$file")"
        ;;
    esac

    set_response_header "Content-Type" "$CONTENT_TYPE"

    read -r CONTENT_LENGTH < <(stat -c'%s' "$file") && \
      set_response_header "Content-Length" "$CONTENT_LENGTH"

    cat "$file"
  fi
}

serve_dir_with_tree() {
  local dir="$1" tree_vers tree_opts basehref x

  set_response_header "Content-Type" "text/html"

  # The --du option was added in 1.6.0.
  read x tree_vers x < <(tree --version)
  [[ $tree_vers == v1.6* ]] && tree_opts="--du"

  tree -H "$2" -L 1 "$tree_opts" -D "$dir"
}

serve_dir_with_ls() {
  local dir=$1
  set_response_header "Content-Type" "text/plain"
  ls -la "$dir"
}

serve_dir() {
  # If `tree` is installed, use that for pretty output.
  if which tree &>/dev/null; then
    serve_dir_with_tree "$@"
  else
    serve_dir_with_ls "$@"
  fi
}

serve_dir_or_file_from() {
  local root="$1"
  local file="${3-${2-}}"
  local URL_PATH="${root}/${file}"

  # sanitize URL_PATH
  URL_PATH=${URL_PATH//[^a-zA-Z0-9_~\-\.\/]/}
  [[ $URL_PATH == *..* ]] && fail_with 400

  # Serve index file if exists in requested directory
  [[ -d $URL_PATH && -f $URL_PATH/index.html && -r $URL_PATH/index.html ]] && \
    URL_PATH="$URL_PATH/index.html"

  if [[ -f $URL_PATH ]] && [[ -r $URL_PATH ]]; then
    serve_file "$URL_PATH" "$@"
  elif [[ -d $URL_PATH ]] && [[ -x $URL_PATH ]]; then
    serve_dir  "$URL_PATH" "$@"
  fi
}

serve_static_string() {
  set_response_header "Content-Type" "text/plain"
  echo "$1"
}

# https://stackoverflow.com/a/37840948/376773
decode_url() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }

get_request_header() {
  local name="$1"
  shopt -s nocasematch
  for header in "${REQUEST_HEADERS[@]}"; do
    if [[ "${header}" == "${name}:"* ]]; then
      local index="$((${#name} + 2))"
      echo "${header:$index}"
      return 0
    fi
  done

  # If we got to here then the header was not found
  return 1
}

get_request_body() {
  local length="$(get_request_header "content-length")"
  if [ ! -z "${length}" ]; then
    recv "Reading ${length} byte request body"
    read_bytes "${length}"
  else
    local encoding="$(get_request_header "transfer-encoding")"
    if [ "${encoding}" = "chunked" ]; then
      while IFS='' read -r line; do
        line=${line%%$'\r'}
        #recv "$line"

        length="$(printf "%d" "0x${line%%$'\n'}")"

        if [ "${length}" -gt 0 ]; then
          recv "Reading ${length} byte chunk"
          read_bytes "${length}"

          # The next two bytes are supposed to be '\r\n'
          #recv "Reading 2 byte end"
          # TODO: add verification
          read_bytes 2 > /dev/null
          recv "Done with chunk"
        else
          recv "Done reading chunked body"
          break
        fi
      done
    fi
  fi
}

on_uri_match() {
  local regex=$1
  shift
  [[ $REQUEST_URI =~ $regex ]] && "$@" "${BASH_REMATCH[@]}"
}

unconditionally() {
  "$@" "$REQUEST_URI"
}

run_user_code() {
  source "${conf}"
}

get_request_body | run_user_code | flush_response
