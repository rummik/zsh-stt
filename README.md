# Zsh STT (Speech To Text)
It's one of those things.

## Installing
```sh
antigen rummik/stt
```

## Usage
Type `stt`, say 'open firefox'.  Firefox should now open (provided you have
VoX and Curl installed).

## Extending
Add commands by defining `-stt-cmd-COMMAND`.

```sh
function -stt-cmd-say {
	-stt-say $@
}
```
