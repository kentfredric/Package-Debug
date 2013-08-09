use strict;
use warnings;

package Package::Debug::Object;

# ABSTRACT: Object oriented guts to Package::Debug

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Package::Debug::Object",
    "interface":"class"
}

=end MetaPOD::JSON

=head1 STYLES

=head2 C<env_key_styles>

=head3 C<default>

Uses L<< C<env_key_from_package>|/env_key_from_package >>

=cut

my %env_key_styles = ( default => 'env_key_from_package', );

=head2 C<env_key_prefix_styles>

=head3 C<default>

Uses L<< C<env_key_prefix_from_package>|/env_key_prefix_from_package >>

=cut

my %env_key_prefix_styles = ( default => 'env_key_prefix_from_package', );

=head2 C<log_prefix_styles>

=head3 C<short>

Uses L<< C<log_prefix_from_package_short>|/log_prefix_from_package_short >>

=head3 C<long>

Uses L<< C<log_prefix_from_package_long>|/log_prefix_from_package_long >>

=cut

my %log_prefix_styles = (
  short => 'log_prefix_from_package_short',
  long  => 'log_prefix_from_package_long',
);

=head2 C<debug_styles>

=head3 C<prefixed_lines>

Uses L<< C<debug_prefixed_lines>|/debug_prefixed_lines >>

=head3 C<verbatim>

Uses L<< C<debug_verbatim>|/debug_verbatim >>

=cut

my %debug_styles = (
  'prefixed_lines' => 'debug_prefixed_lines',
  'verbatim'       => 'debug_verbtaim',
);

=method C<new>

    my $object = Package::Debug::Object->new(%args);

=cut

sub new {
  my ( $self, %args ) = @_;
  return bless \%args, $self;
}

=method C<debug_style>

=method C<set_debug_style>

=attr C<debug_style>

The debug printing style to use.

    'prefixed_lines'

See L<< C<debug_styles>|/debug_styles >>

=cut

sub debug_style {
    return $_[0]->{debug_style} if exists $_[0]->{debug_style};
    return ( $_[0]->{debug_style} = 'prefixed_lines' );
}
sub set_debug_style {
    $_[0]->{debug_style} = $_[1]; return $_[0];
}

=method C<env_key_aliases>

=method C<set_env_key_aliases>

=attr C<env_key_aliases>

A C<[]> of C<%ENV> keys that also should trigger debugging on this package.

    []

=cut

sub env_key_aliases {
    return $_[0]->{env_key_aliases} if exists $_[0]->{env_key_aliases};
    return ( $_[0]->{env_key_aliases} = [] );
}
sub set_env_key_aliases {
    $_[0]->{env_key_aliases} = $_[1]; return $_[0];
}

=method C<env_key_prefix_style>

=method C<set_env_key_prefix_style>

=attr C<env_key_prefix_style>

The mechanism for determining the C<prefix> for the C<%ENV> key.

    'default'

See  L<< C<env_key_prefix_styles>|/env_key_prefix_styles >>
=cut

sub env_key_prefix_style {
    return $_[0]->{env_key_prefix_style} if exists $_[0]->{env_key_prefix_style};
    return ( $_[0]->{env_key_prefix_style} = 'default' );
}
sub set_env_key_prefix_style {
    $_[0]->{env_key_prefix_style} = $_[1]; return $_[0];
}

=method C<env_key_style>

=method C<set_env_key_style>

=attr C<env_key_style>

The mechanism for determining the final C<%ENV> key for turning on debug.

    'default'

See L<< C<env_key_styles>|/env_key_styles >>

=cut

sub env_key_style {
    return $_[0]->{env_key_style} if exists $_[0]->{env_key_style};
    return ( $_[0]->{env_key_style} = 'default' );
}
sub set_env_key_style {
    $_[0]->{env_key_style} = $_[1]; return $_[0];
}

=method C<into>

=method C<set_into>

=attr C<into>

The package we're injecting into.

B<IMPORTANT>: This field cannot vivify itself and be expected to work.

Because much code in this module depends on this field,
if this field is B<NOT> populated explicitly by the user, its likely
to increase the stack depth, invalidating any value if L<< C<into_level>|/into_level >> that was specified.

See L<< C<auto_set_into>|/auto_set_into >>

=cut

sub into {
    return $_[0]->{into} if exists $_[0]->{into};
    die 'Cannot vivify ->into automatically, pass to constructor or ->set_into() or ->auto_set_into()';
}
sub set_into {
    $_[0]->{into} = $_[1]; return $_[0];
}

=method C<into_level>

=method C<set_into_level>

=attr C<into_level>

The number of levels up to look for C<into>

Note, that this value is expected to be provided by a consuming class somewhere, and is expected to be
simply passed down from a user.

See  L<< C<auto_set_into>|/auto_set_into >> for how to set C<into> sanely.

=cut

sub into_level {
    return $_[0]->{into_level} if exists $_[0]->{into_level};
    return ( $_[0]->{into_level} = 0 );
}
sub set_into_level {
    $_[0]->{into_level} = $_[1]; return $_[0];
}

=method C<sub_name>

=method C<set_sub_name>

=attr C<sub_name>

The name of the C<CODEREF> that will be installed into C<into>

    'DEBUG'

=cut

sub sub_name {
    return $_[0]->{sub_name} if exists $_[0]->{sub_name};
    return ( $_[0]->{sub_name} = 'DEBUG' );
}
sub set_sub_name {
    $_[0]->{sub_name} = $_[1]; return $_[0];
}

=method C<value_name>

=method C<set_value_name>

=attr C<value_name>

The name of the C<$SCALAR> that will be installed into C<into>

    'DEBUG' ## $DEBUG

=cut

sub value_name {
    return $_[0]->{value_name} if exists $_[0]->{value_name};
    return ( $_[0]->{value_name} = 'DEBUG' );
}
sub set_value_name {
    $_[0]->{value_name} = $_[1]; return $_[0];
}
=method C<env_key>

=method C<set_env_key>

=attr C<env_key>

The name of the primary C<%ENV> key that controls debugging of this package.

If unspecified, will be determined by the L<< C<env_key_style>|/env_key_style >>

Usually, this will be something like

    <env_key_prefix>_DEBUG

And where C<env_key_prefix> is factory,

    <magictranslation(uc(into))>_DEBUG

Aka:

    SOME_PACKAGE_NAME_DEBUG

=cut


sub env_key {
  return $_[0]->{env_key} if exists $_[0]->{env_key};
  my $style = $_[0]->env_key_style;
  if ( not exists $env_key_styles{$style} ) {
    die "No such env_key_style $style, options are @{ keys %env_key_styles }";
  }
  my $method = $env_key_styles{$style};
  return ( $_[0]->{env_key} = $_[0]->$method() );
};
sub set_env_key {
    $_[0]->{env_key} = $_[1]; return $_[0];
}

=method C<env_key_prefix>

=method C<set_env_key_prefix>

=attr C<env_key_prefix>

The name of the B<PREFIX> to use for C<%ENV> keys for this package.

If unspecified, will be determined by the L<< C<env_key_prefix_style>|/env_key_prefix_style >>

Usually, this will be something like

    <magictranslation(uc(into))>

Aka:

    SOME_PACKAGE_NAME

=cut

sub env_key_prefix {
  return $_[0]->{env_key_prefix} if exists $_[0]->{env_key_prefix};
  my $style = $_[0]->env_key_prefix_style;
  if ( not exists $env_key_prefix_styles{$style} ) {
    die "No such env_key_prefix_style $style, options are @{ keys %env_key_prefix_styles }";
  }
  my $method = $env_key_prefix_styles{$style};
  return ( $_[0]->{env_key_prefix} =  $_[0]->$method() );
};
sub set_env_key_prefix {
  $_[0]->{env_key_prefix} = $_[1]; return $_[0];
}
=method C<debug_sub>

=method C<set_debug_sub>

=attr C<debug_sub>

The actual code ref to install to do the real debugging work.

This is mostly an implementation detail, but if you were truly insane, you could pass a custom C<coderef>
to construction, and it would install the C<coderef> you passed instead of the one we generate.

Generated using L<< C<debug_style>|/debug_style >>

=cut

sub debug_sub {
    return $_[0]->{debug_sub} if exists $_[0]->{debug_sub};
    my $style = $_[0]->debug_style;
    if ( not exists $debug_styles{$style} ) {
        die "No such debug_style $style, options are @{ keys %debug_styles }";
    }
    my $method = $debug_styles{$style};
    return ( $_[0]->{debug_sub} = $_[0]->$method() );
}
sub set_debug_sub {
    $_[0]->{debug_sub} = $_[1]; return $_[0];
}

=method C<log_prefix_style>

=method C<set_log_prefix_style>

=attr C<log_prefix_style>

The default style to use for C<log_prefix>.

If not set, defaults to the value of C<$ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE}> if it exists,
or simply C<'short'> if it does not.

See L<< C<log_prefix_styles>|/log_prefix_styles >>

=cut

sub log_prefix_style {
    return $_[0]->{log_prefix_style} if exists $_[0]->{log_prefix_style};
    my $style = 'short';
    $style = $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE} if $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE};
    return ( $_[0]->{log_prefix_style} = $style );
}
sub set_log_prefix_style {
    $_[0]->{log_prefix_style} = $_[1]; return $_[0];
}

=method C<log_prefix>

=method C<set_log_prefix>

=attr C<log_prefix>

The string to prefix to log messages for debug implementations which use prefixes.

If not specified, will be generated from the style specified by L<< C<log_prefix_style>|/log_prefix_style >>

Which will be usually something like

    Foo::Package::Bar # 'long'
    F:P::Bar          # 'short'

=cut

sub log_prefix {
  return $_[0]->{log_prefix} if exists $_[0]->{log_prefix};
  my $style = $_[0]->log_prefix_style;
  if ( not exists $log_prefix_styles{$style} ) {
    die "Unknown prefix style $style, should be one of @{ keys %log_prefix_styles }";
  }
  my $method = $log_prefix_styles{$style};
  return ( $_[0]->{log_prefix} = $_[0]->$method() );
};
sub set_log_prefix {
  $_[0]->{log_prefix} = $_[1]; return $_[0];
}

=method C<is_env_debugging>

=method C<set_is_env_debugging>

=attr C<is_env_debugging>

The determination as to whether or not the C<%ENV> indicates debugging should be enabled.

Will always be C<true> if C<$ENV{PACKAGE_DEBUG_ALL}>

And will be C<true> if either L<< C<env_key>|/env_key >> or one of L<< C<env_key_aliases>|/env_key_aliases >>
is C<true>.

B<NOTE:> This value I<BINDS> the first time it is evaluated, so for granular control of debugging at run-time,
you should not be lexically changing C<%ENV>.

Instead, you should be modifying the value of C<$My::Package::Name::DEBUG>

=cut

sub is_env_debugging {
    return $_[0]->{is_env_debugging} if exists $_[0]->{is_env_debugging};
    if ( $ENV{PACKAGE_DEBUG_ALL} ) {
        return ( $_[0]->{is_env_debugging} = 1 );
    }
    for my $key ( $_[0]->env_key, @{ $_[0]->env_key_aliases } ) {
        next unless exists $ENV{$key};
        next unless $ENV{$key};
        return ( $_[0]->{is_env_debugging} = 1 );
    }
    return ( $_[0]->{is_env_debugging} = 0 );
}
sub set_is_env_debugging {
    $_[0]->{is_env_debugging} = $_[1];
    return $_[0];
}

=method C<into_stash>

=cut

sub into_stash {
    return $_[0]->{into_stash} if exists $_[0]->{into_stash};
    require Package::Stash;
    return ( $_[0]->{into_stash} = Package::Stash->new( $_[0]->into ));
}
sub set_into_stash {
    $_[0]->{into_stash} = $_[1]; return $_[0];
}

=method C<auto_set_into>

This method any plumbing will want to call.

    $object->auto_set_into( $number_of_additional_stack_levels );

Takes a parameter to indicate the expected additional levels of stack will be need.

For instance:

    sub import {
        my ($self, %args ) = @_;
        my $object = ...->new(%args);
        $object->auto_set_into(1); # needs to be bound to the caller to import->()
    }

Or

    sub import {
        my ($self, %args ) = @_;
        my $object = ...->new(%args);
        __PACKAGE__->bar($object);

    }
    sub bar {
        $_[1]->auto_set_into(2); # skip up to caller of bar, then to caller of import
    }

And in both these cases, the end user just does:

    package::bar->import( into_level =>  0 ); # inject at this level

=cut

sub auto_set_into {
  my ( $self, $add ) = @_;
  $_[0]->{into} = [ caller( $self->into_level + $add ) ]->[0];
  return $self;
}

=method C<debug_prefixed_lines>

    my $code = $object->debug_prefixed_lines;
    $code->( $message );

This Debug implementation returns a C<DEBUG> sub that treats all arguments as lines of message,
and formats them as such:

    [SomePrefix::Goes::Here] this is your messages first line\n
    [SomePrefix::Goes::Here] this is your messages second line\n

The exact prefix used is determined by L<< C<log_prefix>|/log_prefix >>,
and the prefix will be omitted if C<log_prefix> is not defined.

( Note: this will likely require explicit passing of

    log_prefix => undef

)

=cut

# Note: Heavy hand-optimisation going on here, this is the hotpath
sub debug_prefixed_lines {
  my $self   = shift;
  my $prefix = $self->log_prefix;
  return sub {
    my (@message) = @_;
    for my $line (@message) {
      *STDERR->print( '[' . $prefix . '] ' ) if defined $prefix;
      *STDERR->print($line);
      *STDERR->print("\n");
    }
  };
}

=method C<debug_verbatim>

This Debug implementation returns a C<DEBUG> sub that simply
passes all parameters to C<< *STDERR->print >>, as long as debugging is turned on.

    my $code = $object->debug_verbatim;
    $code->( $message );


=cut

sub debug_verbatim {
  my $self = shift;
  return sub {
    *STDERR->print(@_);
  };
}

=method C<env_key_from_package>

This C<env_key_style> simply appends C<_DEBUG> to the C<env_key_prefix>

    my $key = $object->env_key_from_package;

=cut

sub env_key_from_package {
  return $_[0]->env_key_prefix() . '_DEBUG';
}

=method C<env_key_prefix_from_package>

This L<< C<env_key_prefix_style>|/env_prefix_style >> converts L<< C<into>|/into >> to a useful C<%ENV> name.

    Hello::World::Bar -> HELLO_WORLD_BAR

Usage:

    my $prefix = $object->env_key_prefix_from_package;

=cut

sub env_key_prefix_from_package {
  my $package = $_[0]->into;
  $package =~ s{
    ::
  }{_}msxg;
  return uc $package;
}

=method C<log_prefix_from_package_short>

This L<< C<log_prefix_style>|/log_prefix_style >> determines a C<short> name by mutating C<into>.

When the name is C<< <10 chars >> it is passed unmodified.

Otherwise, it is tokenised, and all tokens bar the last are reduced to either

=over 4

=item a - groups of upper case only characters

=item b - failing case a, single lower case characters.

=back

    Hello -> H
    HELLO -> HELLO
    DistZilla -> DZ
    mutant -> m

And then regrouped and the last attached

    This::Is::A::Test -> T:I:A::Test
    NationalTerrorismStrikeForce::SanDiego::SportsUtilityVehicle -> NTSF:SD::SportsUtilityVehicle

Usage:

    my $prefix = $object->log_prefix_from_package_short;

=cut

sub log_prefix_from_package_short {
  my $package = $_[0]->into;
  if ( ( length $package ) < 10 ) {
    return $package;
  }
  my (@tokens) = split /::/msx, $package;
  my ($suffix) = pop @tokens;
  for (@tokens) {
    if ( $_ =~ /[[:upper:]]/msx ) {
      $_ =~ s/[[:lower:]]+//msxg;
      next;
    }
    $_ = substr $_, 0, 1;
  }
  my ($prefix) = join q{:}, @tokens;
  return $prefix . q{::} . $suffix;
}

=method C<log_prefix_from_package_long>

This L<< C<log_prefix_style>|/log_prefix_style >> simply returns C<into> as-is.

Usage:

    my $prefix = $object->log_prefix_from_package_long;

=cut

sub log_prefix_from_package_long {
  return $_[0]->into;
}

=method C<inject_debug_value>

Optimistically injects the desired C<$DEBUG> symbol into the package determined by C<value_name>.

Preserves the existing value if such a symbol already exists.

    $object->inject_debug_value();

=cut

sub inject_debug_value {
  my $value_name = $_[0]->value_name;
  return if not defined $value_name;
  my $value = $_[0]->is_env_debugging;
  my $stash = $_[0]->into_stash;
  if ( $stash->has_symbol('$' . $value_name) ) {
    $value = $stash->get_symbol('$' . $value_name);
    $stash->remove_symbol('$' . $value_name);
  }
  $stash->add_symbol('$' . $value_name, \$value );
}

sub _wrap_debug_sub {
  my $sub_name = $_[0]->sub_name;
  return if not defined $sub_name;
  my $value_name  = $_[0]->value_name;
  my $is_env_debugging = $_[0]->is_env_debugging;
  if ( not defined $value_name and not $is_env_debugging ) {
    return sub { };
  }
  my $real_debug = $_[0]->debug_sub;
  my $symbol = $_[0]->into_stash->get_symbol('$' . $value_name );
  return sub {
    return unless ${$symbol};
    goto $real_debug;
  };
}

=method C<inject_debug_sub>

Injects the desired code reference C<DEBUG> symbol into the package determined by C<sub_name>

    $object->inject_debug_sub();

=cut

sub inject_debug_sub {
  $_[0]->into_stash->add_symbol( '&' . $_[0]->sub_name, $_[0]->_wrap_debug_sub );
}

1;
