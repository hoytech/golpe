#!/usr/bin/env perl

use strict;

foreach my $fbsFile (glob('fbs/*.fbs')) {
    flatc($fbsFile, 'build');
}


sub flatc {
    my $fbsFile = shift || die "need fbs filename";
    my $buildDir = shift || die "need build dir";

    open(my $fh, "-|", qw{flatc --cpp --reflect-names -o}, $buildDir, $fbsFile) || die "unable to run flatc: $!";

    while (<$fh>) {
        next if /warning: field names should be lowercase snake_case/;
        print;
    }

    wait;
    die "flatc failure building $fbsFile" if $?;
}
