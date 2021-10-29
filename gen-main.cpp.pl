#!/usr/bin/env perl

use strict;

use FindBin;
use Data::Dumper;

use YAML;
use Template;


my $appDef = YAML::LoadFile('./app-def.yaml');


my @cmds = map { /^cmd_(.*)\.cpp$/ && $1 } glob('cmd_*.cpp');

my $ctx = {
    appDef => $appDef,
    cmds => \@cmds,
};


my $tt = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => ".",
}) || die "$Template::ERROR\n";

$tt->process("golpe/main.cpp.tt", $ctx, "build/main.cpp") || die $tt->error(), "\n";
