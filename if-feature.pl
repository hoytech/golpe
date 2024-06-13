#!/usr/bin/env perl

use strict;

use Data::Dumper;
use Template;

use FindBin;
use lib "$FindBin::Bin/";
use LoadGolpe;


my $golpe = LoadGolpe::load();


my $features = shift // die "need feature";
my $ifCond = shift // die "need if conf";
my $elseCond = shift // '';

for my $f (split /,/, $features) {
    if ($golpe->{features}->{$f}) {
        print "$ifCond\n";
        exit;
    }
}

print "$elseCond\n";
