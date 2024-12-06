# SShazam

Shazam for SailfishOS. WIP

You can click on a track in history or the recognition result to show metadata and artworks. In that menu you can swipe artworks and click on an artwork to hide the overlayed metadata.

## Known issues

- armv7hl builds are slow at processing. This is because armv7hl doesn't use Rust for now
- recognition button is blurry

## Translating

Read instructions [here](https://gist.github.com/roundedrectangle/c4ac530ca276e0d65c3593b8491473b6). Make sure not to skip them even if you know how to translate other apps, because there are some pitfalls. When reading instruction, replace `appname` with `sshazam`.

## Building

Make sure to set the variables in SPEC file corrently. They're placed at the top of the file and can contain eathier `yes` or `no` in them.

1. `package_library`: wether to package the library with the app. If you set it to `no` then you should install the library on your phone yourself and disable sandboxing.
    - To install the library, run this command to install Rust version: `python3 -m pip install shazamio pasimple --user --upgrade` and this to install Python-only version: `python3 -m pip install git+https://github.com/roundedrectangle/ShazamIO pasimple --user --upgrade`
2. `use_rust`: wether to use Rust or pure Python. Rust is recommended, but not supported on armv7hl.

## TODO

- optimze SVGs