#!/usr/bin/env perl

use strict;

use FindBin;
use Data::Dumper;

use YAML;
use Template;

die "app-def.yaml is deprecated, use golpe.yaml" if -e "./app-def.yaml";
die "schema.yaml is deprecated, use golpe.yaml" if -e "./schema.yaml";
my $golpe = YAML::LoadFile('./golpe.yaml');


my @cmds = map { m{^src/cmd_(.*)\.cpp$} && $1 } glob('src/cmd_*.cpp');

my $ctx = {
    golpe => $golpe,
    cmds => \@cmds,
};


my $tt = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => ".",
}) || die "$Template::ERROR\n";

$tt->process("golpe/main.cpp.tt", $ctx, "build/main.cpp") || die $tt->error(), "\n";
