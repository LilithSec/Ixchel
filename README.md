# Ixchel

Configuration and templating system meant to be used Ansible or
Rex. Config generated centeral and pushed out and templating/actions
done based on that on the remote systems for purpose of continual
integration pipe line for server configuration as well as setup.

## Setup



## Install

Perl modules needed.

- Config::Tiny
- Data::Dumper
- File::Find::Rule
- File::ShareDir
- File::Slurp
- Hash::Merge
- JSON
- JSON::Path
- LWP::Simple
- Module::List
- Rex
- String::ShellQuote
- TOML
- Template
- YAML::XS

Other Libraries.

- libyaml

### Debian

1. `apt-get install libconfig-tiny-perl libfile-find-rule-perl
libfile-sharedir-perl libfile-slurp-perl libhash-merge-perl
libjson-perl libjson-path-perl libwww-perl rex
libstring-shellquote-perl libtoml-perl libtemplate-perl
libyaml-libyaml-perl cpanminus`
2. `cpanm Ixchel`

### FreeBSD

1. `pkg intall p5-Config-Tiny p5-Data-Dumper p5-File-Find-Rule
p5-File-ShareDir p5-File-Slurp p5-Hash-Merge p5-JSON p5-JSON-Path
p5-libwww p5-Module-List p5-Rex p5-String-ShellQuote p5-TOML
p5-Template-Toolkit p5-YAML-LibYAML p5-App-cpanminus`
2. `cpanm Ixchel`

## TODO

- sub path selection for xeno when passing hashes
- easy init method for CMDB build stuff
- Suricata/Sagan config comparison
- Sagan rules file ingestion to TOML
- Apache config management(genearlized manner)
- actions for...
  - Lilith
	- install client
	- db server setup
  - Suricata::Extract
  - CAPEv2
  - autcron template
  - extend_logsize template
  - snmp_v2 template
  - snmp setup
- better documentation for Suricata outputs
