#!/usr/bin/env perl

use strict;

system('mkdir -p build/');

my $versionHeader = 'build/app_git_version.h';

my $gitVer;

{
    my $commitNum = `git rev-list --count --first-parent HEAD`;
    chomp $commitNum;
    my $commitHash = `git rev-parse HEAD`;
    $commitHash = substr($commitHash, 0, 7);
    $gitVer = "v$commitNum-$commitHash";
}

{
    open(my $fh, '>', "$versionHeader.new") || die "failed to write git version: $!";
    print $fh <<"END";
#pragma once

#define APP_GIT_VERSION "$gitVer"
END
}

rename("$versionHeader.new", $versionHeader) if !-e $versionHeader || `diff $versionHeader $versionHeader.new`;
unlink("$versionHeader.new");
