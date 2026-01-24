# Hobby OS

## Requirements

Convert a music file to a raw file with 44.1 KHz, 1 channel, and 16-bit signed samples.

```sh
sox data.mp3 -r 44100 -c 1 -b 16 -e signed-integer src/kernel/data.raw
```
