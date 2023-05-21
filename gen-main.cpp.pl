#!/usr/bin/env perl

use strict;

use FindBin;
use Data::Dumper;

use YAML;
use Template;

my $apps = shift // die "need list of apps";


die "app-def.yaml is deprecated, use golpe.yaml" if -e "./app-def.yaml";
die "schema.yaml is deprecated, use golpe.yaml" if -e "./schema.yaml";
my $golpe = YAML::LoadFile('./golpe.yaml');


my $ctx = {
    golpe => $golpe,
    cmds => [ map { m{^src/cmd_(.*)\.cpp$} && $1 } glob('src/cmd_*.cpp') ],
    apps => [],
};

for my $app (split / /, $apps) {
    my @cmds = map { m{/cmd_(.*)\.cpp$} && $1 } glob("src/apps/$app/cmd_*.cpp");
    push @{ $ctx->{apps} }, {
        name => $app,
        cmds => \@cmds,
    };
}


my $tt = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => ".",
}) || die "$Template::ERROR\n";

$tt->process("golpe/main.cpp.tt", $ctx, "build/main.cpp") || die $tt->error(), "\n";
