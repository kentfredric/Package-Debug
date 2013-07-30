use strict;
use warnings;

package Package::Debug;

# ABSTRACT: Add ENV/Config controlled debug tokens to your code

=head1 SYNOPSIS

There is a lot of code on C<CPAN> that has something like this in it:

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

The defacto C<DEBUG()> stub when not in a debug environment should be a no-op, or as close to a no-op as possible.

However, when debugging is turned on, debugging back ends should also be controllable via env/configuaration,
and proxy to things like Log::Message and friends.

=item * Per-package debug granularity

Every package will get its own independent DEBUG key, and DEBUG for a class can be toggled
with an C<%ENV> key relevant to that class.

=item * Global Debugging

In addition to package level granularity, global debugging can also be enabled, while still seeing the individual packages the debug message emanates from.

=back

=cut

sub import {
  my ( $self, %args ) = @_;
  require Package::Debug::Object;
  my $object = Package::Debug::Object->new(%args);
  $object->auto_set_into(1);
  $object->inject_debug_value();
  $object->inject_debug_sub();
  return $object;
}

=head1 PERFORMANCE

For the best speed,

    use Package::Debug;

This will do its best to produce a C<no-op> sub when debugging is not requested by C<%ENV>

However, this comes at a price, namely, if you want to turn on debugging in code, you have to either

    BEGIN {  $ENV{YOUR_PACKAGE_NAME_DEBUG} = 1 }
    use Your::Package::Name;
    # debugging is on

Or

    BEGIN {  $Your::Package::Name::DEBUG = 1 }
    use Your::Package::Name;
    # debugging is on

And this will not work:

    use Your::Package::Name;
    $Your::Package::Name::DEBUG = 1; # Modification of Readonly value

This is because for the last example to work, the C<DEBUG> sub would have to check that value every time it was called.

And this will roughly double the cost of calling C<DEBUG>

=head2 If you want run time adjustment

    use Package::Debug runtime_switchable => 1;

This will

=over 4

=item a - not make C<$DEBUG> C<readonly> during import.

=item b - inject a C<DEBUG> C<sub> that checks the value of the former.

=back

=cut

1;
