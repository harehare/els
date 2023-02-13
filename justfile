default: build 

els_version := "v0.0.1"
install_path := "/usr/local/bin/els"
zig_clap_version := "0.6.0"
zig_regex_version := "d73caa2"

setup:
  # zig-string
  git -C libs clone https://github.com/JakubSzark/zig-string.git || true
  # zig-datetime
  git -C libs clone https://github.com/frmdstryr/zig-datetime.git || true
  # zig-clap
  git -C libs clone https://github.com/Hejsil/zig-clap.git || true
  cd libs/zig-clap && git checkout -b {{zig_clap_version}} refs/tags/{{zig_clap_version}} || true
  cd libs/zig-clap && git checkout {{zig_clap_version}}
  # zig-regex
  git -C libs clone https://github.com/tiehuis/zig-regex.git || true
  cd libs/zig-regex && git checkout {{zig_regex_version}}


build arch=arch() os=os():
  zig build -Drelease-fast=true -Dtarget={{arch}}-{{os}} -Doutput=els-{{os}}-{{arch}}-{{els_version}}

install:
  just build
  cp zig-out/bin/els-{{os()}}-{{arch()}}-{{els_version}} {{install_path}}

run *args:
  zig build run -- {{args}}

dev *args:
  just run {{args}}

test:
  zig build test
