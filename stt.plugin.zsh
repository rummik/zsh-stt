#!/bin/zsh
# A speech recognition helper program.
# Requires Curl and SoX.  Export `STT_SOX_BACKEND=alsa` if you don't have
# `libsox-fmt-pulse`.

# Language to be passed to Google's speech API.
export STT_LANG=${STT_LANG:-${${LANG/.*/}/_/-}}

# SoX recording backend.
# It may default to pulseaudio, but you can use alsa if you like.
export STT_SOX_BACKEND=${STT_SOX_BACKEND:-pulseaudio}

# Speech to text operation central.
# This *is* the right road, isn't it?
function stt {
	local api='http://www.google.com/speech-api/v1'

	-stt-record \
		| -stt-request "$api/recognize?lang=$STT_LANG" \
		| -stt-relay-cmd
}

# Relay commands to `-stt-cmd-$1`.
# Hello?  You want to speak to cmd-search?  Connecting you now.
function -stt-relay-cmd {
	read cmd args

	# Convert our command and arguments to lowercase.
	local cmd=${(L)cmd}
	local args=${(L)args}

	if functions -- "-stt-cmd-$cmd" > /dev/null; then
		"-stt-cmd-$cmd" ${=args}
	else
		-stt-unknown-cmd "$cmd" ${=args}
	fi
}

# Our only command.
# It opens things when asked politely.
function -stt-cmd-open {
	local cmd=${(L)1}

	if which $cmd > /dev/null; then
		-stt-say Opening \"$cmd\".
		$cmd
	else
		-stt-error Could not open \"$cmd\".
	fi
}

# Say placeholder.
# We use espeak by default, but this can be replaced later by another plugin.
function -stt-say {
	print $@
	espeak <<< $@
}

# Error placeholder.
function -stt-error {
	-stt-say $@ >&2
}

# Unknown command placeholder.
function -stt-unknown-cmd {
	-stt-error Unknown command: \"$1\".
}

# Record some vad silenced audio from the system's mic.
# It's so vad it's good.
function -stt-record {
	rec -q -V1 \
		-t $STT_SOX_BACKEND default \
		-t .flac -c 1 -r 44100 - \
		vad silence -l 0  1 2.0 10%
}

# Prod the API host until it gives utterance.
function -stt-request {
	curl -s $@ \
		--form file=@- \
		--header 'Content-Type: audio/x-flac; rate=44100' \
		| -stt-lazyJSON utterance
}

# Lazy JSON parser.
# Accepts JSON as STDIN, gives a property as output.
# It's sooo bad.
function -stt-lazyJSON {
	grep --color=never -Po "(?<=\"$1\":\")(\\\\.|[^\"])+"
}
