package LoadGolpe;

use strict;

use lib "$FindBin::Bin/vendor/";

use YAML;


sub load {
    die "app-def.yaml is deprecated, use golpe.yaml" if -e "./app-def.yaml";
    die "schema.yaml is deprecated, use golpe.yaml" if -e "./schema.yaml";

    my $output = YAML::LoadFile('./golpe.yaml');

    for my $app (split / /, $ENV{APPS}) {
        my $file = "./src/apps/$app/golpe.yaml";
        next if !-e $file;

        my $output2 = YAML::LoadFile($file);

        $output = merge($output, $output2);
    }

    return $output;
}


sub merge {
    my $x = shift;
    my $y = shift;

    return $y if !defined $x;
    return $x if !defined $y;

    die "type mismatch in app's golpe.yaml" if ref($x) ne ref($y);

    if (ref($x) eq 'ARRAY') {
        return [ @$x, @$y ];
    }

    if (ref($x) eq 'HASH') {
        my $o = { %$x, };

        foreach my $k (keys %$y) {
            $o->{$k} = merge($x->{$k}, $y->{$k});
        }

        return $o;
    }

    return $y;
}


1;
