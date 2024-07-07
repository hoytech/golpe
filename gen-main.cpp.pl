#!/usr/bin/env perl

use strict;

use FindBin;
use lib "$FindBin::Bin/";
use lib "$FindBin::Bin/vendor/";

use LoadGolpe;
use Template;


my $golpe = LoadGolpe::load();


my $ctx = {
    golpe => $golpe,
    cmds => [ map { m{^src/cmd_(.*)\.cpp$} && $1 } glob('src/cmd_*.cpp') ],
    apps => [],
};

for my $app (split / /, $ENV{APPS}) {
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
