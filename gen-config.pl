#!/usr/bin/env perl

use strict;

use FindBin;
use Data::Dumper;

use YAML;
use Template;

my $golpe = YAML::LoadFile('./golpe.yaml');

my $config = $golpe->{config} || [];

my $nested = { name => '', items => [], };

foreach my $c (@$config) {
    $c->{nameCpp} = $c->{name};

    $c->{path} = [ split(/__/, $c->{name}) ];

    if (!defined $c->{type}) {
        if ($c->{default} =~ /^(true|false)$/i) {
            $c->{type} = 'bool';
        } elsif ($c->{default} =~ /^\d+$/) {
            $c->{type} = 'uint64';
        } else {
            $c->{type} = 'string';
        }
    }

    if ($c->{type} eq 'uint64') {
        $c->{typeCpp} = 'uint64_t';
        $c->{defaultCpp} = $c->{default} . 'ULL';
    } elsif ($c->{type} eq 'string') {
        $c->{typeCpp} = 'std::string';
        $c->{defaultCpp} = $c->{default};
        $c->{defaultCpp} =~ s/"/\\"/g;
        $c->{defaultCpp} = '"' . $c->{defaultCpp} . '"';
    } elsif ($c->{type} eq 'bool') {
        $c->{typeCpp} = 'bool';
        $c->{defaultCpp} = lc($c->{default});
    } else {
        die "unknown type: $c->{type}";
    }

    my $n = $nested->{items};
    my $items = [ split(/__/, $c->{name}) ];
    my $lastItem = pop @$items;

    for my $k (@$items) {
        my ($item) = grep { $k eq $_->{name} } @$n;
        if (!$item) {
            $item = { name => $k, items => [], };
            push @$n, $item;
        }
        $n = $item->{items};
    }

    push @$n, {
        key => $lastItem,
        %$c,
    };
}


{
    open(my $fh, '>', "build/$golpe->{appName}.conf") || die "couldn't write to default config";
    my $o = '';
    genDefaultConfig(\$o, $nested, 0);
    print $fh "##\n";
    print $fh "## Default $golpe->{appName} config\n";
    print $fh "##\n\n";
    print $fh $o;
}



my $ctx = {
    config => $config,
};


my $tt = Template->new({
    ABSOLUTE => 1,
    INCLUDE_PATH => ".",
}) || die "$Template::ERROR\n";

$tt->process("golpe/config.h.tt", $ctx, "build/config.h") || die $tt->error(), "\n";
$tt->process("golpe/config.cpp.tt", $ctx, "build/config.cpp") || die $tt->error(), "\n";




sub genDefaultConfig {
    my ($o, $n, $indent) = @_;

    my $prefix = "    " x $indent;

    my $first = 1;

    for my $i (@{ $n->{items} }) {
        $$o .= "\n" if !$first;
        $first = 0;

        if ($i->{items}) {
            $$o .= "$prefix$i->{name} {\n";
            genDefaultConfig($o, $i, $indent + 1);
            $$o .= "$prefix}\n";
        } else {
            $$o .= "$prefix# $i->{desc}\n" if $i->{desc};
            my $default = $i->{default};
            $default = qq{"$default"} if $i->{type} eq 'string';
            $$o .= "$prefix$i->{key} = $default\n";
        }
    }
}
