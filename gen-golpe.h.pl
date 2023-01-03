#!/usr/bin/env perl

use strict;

use FindBin;
use Data::Dumper;

use YAML;
use Template;

my $golpe = YAML::LoadFile('./golpe.yaml');

my $ctx = {
    golpe => $golpe,
    generatedHeaders => [ map { s{^build/+}{}r } glob('build/*_generated.h'), ],
};

$ctx->{useGlobalH} = 1 if -e './global.h';


my $tt = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => ".",
}) || die "$Template::ERROR\n";

$tt->process("golpe/golpe.h.tt", $ctx, "build/golpe.h") || die $tt->error(), "\n";
