#!/usr/bin/env perl

use strict;

use FindBin;
use lib "$FindBin::Bin/";
use lib "$FindBin::Bin/vendor";

use LoadGolpe;
use Template;


my $golpe = LoadGolpe::load();


my $ctx = {
    golpe => $golpe,
    generatedHeaders => [ map { s{^build/+}{}r } glob('build/*_generated.h'), ],
};

$ctx->{useGlobalH} = 1 if -e './src/global.h';


my $tt = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => ".",
}) || die "$Template::ERROR\n";

$tt->process("golpe/golpe.h.tt", $ctx, "build/golpe.h") || die $tt->error(), "\n";
