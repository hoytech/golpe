package BuildLib;

use strict;

use File::Temp;
use Cwd;

require Exporter;
use base 'Exporter';
our @EXPORT = qw(sys slurp_file unslurp_file);



sub fpm {
    my $args = shift;

    my $cwd = cwd();

    $args->{version} //= get_version();
    $args->{description} //= $args->{name};


    die "need to install fpm ( https://github.com/jordansissel/fpm )"
        if !`which fpm`;

    my $tmp = File::Temp::tempdir(CLEANUP => 1);

    sys("mkdir -p dist");

    foreach my $type (@{ $args->{types} }) {
        foreach my $src (keys %{ $args->{files} }) {
            my $dest = "$tmp/$args->{files}->{$src}";

            my $dest_path = $dest;
            $dest_path =~ s{[^/]+\z}{};

            sys("mkdir -p $dest_path") if !-d $dest_path;
            sys("cp $src $dest");
        }

        foreach my $src (keys %{ $args->{dirs} }) {
            my $dest = "$tmp/$args->{dirs}->{$src}";

            sys("mkdir -p $dest");
            sys("cp -r $src/* $dest");
        }


        my $changelog = '';

        if (exists $args->{changelog}) {
            my $changelog_path = "$cwd/$args->{changelog}";

            if ($type eq 'deb') {
                $changelog = qq{ --deb-changelog "$changelog_path" };
            } elsif ($type eq 'rpm') {
                ## FIXME: fpm breaks?
                #$changelog = qq{ --rpm-changelog "$changelog_path" };
            } else {
                die "unknown type: $type";
            }
        }


        my $config_files = '';

        foreach my $config_file (@{ $args->{config_files} }) {
            $config_files .= "--config-files '$config_file' ";
        }


        my $deps_list;

        if ($type eq 'deb') {
            $deps_list = $args->{deps_deb} || $args->{deps};
        } elsif ($type eq 'rpm') {
            $deps_list = $args->{deps_rpm};
        }

        my $deps = '';

        foreach my $dep (@$deps_list) {
            $deps .= "-d '$dep' ";
        }


        my $postinst = '';

        if (exists $args->{postinst}) {
            $postinst = qq{ --after-install "$cwd/$args->{postinst}" };
        }


        my $cmd = qq{
            cd dist ; fpm
              -n "$args->{name}"
              -s dir -t $type
              -v $args->{version}

              --description "$args->{description}"
              --vendor ''

              $deps
              $changelog
              $postinst
              $config_files

              -f -C $tmp .
        };

        $cmd =~ s/\s+/ /g;
        $cmd =~ s/^\s*//;

        sys($cmd);
    }
}



sub sys {
    my $cmd = shift;
    print "$cmd\n";
    system($cmd) && die;
}



sub get_version {
    my $git_commit_count = `git rev-list --count --first-parent HEAD`;
    chomp $git_commit_count;

    my $git_rev = `git rev-parse HEAD`;
    chomp $git_rev;
    $git_rev = substr($git_rev, 0, 7);

    my $ver = "1.0.0-$git_commit_count-$git_rev";

    ## Add a "0" to fix issue where dpkg dies if a version component doesn't contain any base-10 digits
    ## (which happens if the first 7 hex digits in a hash are all [a-f])
    $ver =~ s/-g([0-9a-f]+)$/-0g$1/;

    return $ver;
}



sub slurp_file {
    my $filename = shift // die "need filename";

    open(my $fh, '<', $filename) || die "couldn't open '$filename' for reading: $!";

    local $/;
    return <$fh>;
}

sub unslurp_file {
    my $contents = shift;
    my $filename = shift;

    open(my $fh, '>', $filename) || die "couldn't open '$filename' for writing: $!";

    print $fh $contents;
}


1;
