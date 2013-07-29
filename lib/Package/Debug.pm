use strict;
use warnings;

package Package::Debug;
BEGIN {
  $Package::Debug::AUTHORITY = 'cpan:KENTNL';
}
{
  $Package::Debug::VERSION = '0.1.0';
}

# ABSTRACT: Add ENV/Config controlled debug tokens to your code


sub import {
  my ( $self, %args ) = @_;
  require Package::Debug::Object;
  my $object = Package::Debug::Object->new(%args);
  $object->auto_set_into(1);
  $object->inject_debug_value();
  $object->inject_debug_sub();
}
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Package::Debug - Add ENV/Config controlled debug tokens to your code

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

There is a lot of code on CPAN that has something like this in it:

    our $DEBUG = $ENV{MY_PACKAGE_NAME_DEBUG};

or something like

    sub DEBUG {
        return if not $ENV{MY_PACKAGE_NAME_DEBUG};
        <real debug code>
    }

or something like:

    if( $ENV{MY_PACKAGE_NAME_DEBUG} ) {
        *DEBUG=sub{ withdebug }
    } else {
        *DEBUG=sub { noop }
    }

These are mostly simple and straight forward, ... however, they artificially limit what you can do,
at the cost of making ugly code.

This module aims to implement the common utility, with less fuss:

    $ENV{MY_BAZ_DEBUG} = 1;

    package My::Baz;

    use Package::Debug;

    ...

    sub foo {
        DEBUG("message");
    }

And all the right things should still occur.

Additionally, this module will eventually add a bunch of features, that are by default off, but can be toggled
on using environment or configuration files.

=head1 EXPECTED FEATURES

=over 4

=item * Deferrable debug mechanism

The defacto DEBUG() stub when not in a debug environment should be a noop.

However, when debugging is turned on, debugging backends should also be controllable via env/configuaration, 
and proxy to things like Log::Message and friends.

=item * Per-package debug granularity

Every package will get its own independent DEBUG class, and DEBUG for a class can be toggled
with an ENV key relevant to that class.

=item * Global Debugging

In addition to package level granularity, global debugging can also be enabled, while still seeing the individual packages the debug message eminates from.

=back

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
