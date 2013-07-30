use strict;
use warnings;

package Package::Debug::Object;
BEGIN {
  $Package::Debug::Object::AUTHORITY = 'cpan:KENTNL';
}
{
  $Package::Debug::Object::VERSION = '0.1.0';
}

# ABSTRACT: Object oriented guts to Package::Debug

use Readonly;


my %env_key_styles = ( default => 'env_key_from_package', );


my %env_key_prefix_styles = ( default => 'env_key_prefix_from_package', );


my %log_prefix_styles = (
  short => 'log_prefix_from_package_short',
  long  => 'log_prefix_from_package_long',
);


my %debug_styles = (
  'prefixed_lines' => 'debug_prefixed_lines',
  'verbatim'       => 'debug_verbtaim',
);


sub new {
  my ( $self, %args ) = @_;
  return bless \%args, $self;
}


sub _accessor {
  my ( $package, $name, $builder ) = @_;
  return <<"_AC_";
sub ${package}::${name} {
    return \$_[0]->{$name} if exists \$_[0]->{$name};
    return ( \$_[0]->{$name} = \$_[0]->${builder}(splice \@_,1) );
}
_AC_
}

sub _setter {
  my ( $package, $name ) = @_;
  return <<"_SET_";
    sub ${package}::set_${name} {
        \$_[0]->{$name} = \$_[1]; return \$_[0];
    };
_SET_
}

sub _has {
  my ( $name, $builder ) = @_;
  local $@ = undef;
  my $package = __PACKAGE__;
  my $builder_code;
  if ( ref $builder ) {
    $builder_code = "*${package}::_build_${name} = \$builder;";
  }
  else {
    $builder_code = "sub ${package}::_build_${name} { $builder }";
  }

  my $code = $builder_code . _accessor( $package, $name, "_build_$name" ) . _setter( $package, $name, "_build_$name" );

  ## no critic (ProhibitStringyEval)
  if ( not eval "$code; 1" ) {
    die "Compiling code << sub { $code } >> failed. $@";
  }
  return 1;
}


_has debug_style => q[ 'prefixed_lines' ];


_has env_key_aliases => q[ []  ];


_has env_key_prefix_style => q[ 'default' ];


_has env_key_style => q[ 'default' ];


_has full_sub_name => q[ return if not $_[0]->sub_name   ; $_[0]->into . '::' . $_[0]->sub_name   ];


_has full_value_name => q[ return if not $_[0]->value_name ; $_[0]->into . '::' . $_[0]->value_name ];


_has into => q[ die 'Cannot vivify ->into automatically, pass to constructor or ->set_into() or ->auto_set_into()' ];


_has into_level => q[ 0 ];


_has sub_name => q[ 'DEBUG' ];


_has value_name => q[ 'DEBUG' ];


_has env_key => sub {
  my $style = $_[0]->env_key_style;
  if ( not exists $env_key_styles{$style} ) {
    die "No such env_key_style $style, options are @{ keys %env_key_styles }";
  }
  my $method = $env_key_styles{$style};
  return $_[0]->$method();
};


_has env_key_prefix => sub {
  my $style = $_[0]->env_key_prefix_style;
  if ( not exists $env_key_prefix_styles{$style} ) {
    die "No such env_key_prefix_style $style, options are @{ keys %env_key_prefix_styles }";
  }
  my $method = $env_key_prefix_styles{$style};
  return $_[0]->$method();
};


_has debug_sub => sub {
  my $style = $_[0]->debug_style;
  if ( not exists $debug_styles{$style} ) {
    die "No such debug_style $style, options are @{ keys %debug_styles }";
  }
  my $method = $debug_styles{$style};
  return $_[0]->$method();
};


_has log_prefix_style => sub {
  return $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE} if $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE};
  return 'short';
};


_has log_prefix => sub {
  my $style = $_[0]->log_prefix_style;
  if ( not exists $log_prefix_styles{$style} ) {
    die "Unknown prefix style $style, should be one of @{ keys %log_prefix_styles }";
  }
  my $method = $log_prefix_styles{$style};
  $_[0]->$method();
};


_has is_env_debugging => sub {
  if ( $ENV{PACKAGE_DEBUG_ALL} ) {
    return 1;
  }
  for my $key ( $_[0]->env_key, @{ $_[0]->env_key_aliases } ) {
    next unless exists $ENV{$key};
    next unless $ENV{$key};

    return 1;
  }
  return;
};


_has runtime_switchable => sub { 0 };


sub auto_set_into {
  my ( $self, $add ) = @_;
  $_[0]->{into} = [ caller( $self->into_level + $add ) ]->[0];
  return $self;
}


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


sub debug_verbatim {
  my $self = shift;
  return sub {
    *STDERR->print(@_);
  };
}


sub env_key_from_package {
  return $_[0]->env_key_prefix() . '_DEBUG';
}


sub env_key_prefix_from_package {
  my $package = $_[0]->into;
  $package =~ s{
    ::
  }{_}msxg;
  return uc $package;
}


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


sub log_prefix_from_package_long {
  return $_[0]->into;
}


sub _has_value {
  my $ns = do { no strict 'refs'; \%{ $_[0] . q{::} } };
  return if not exists $ns->{ $_[1] };
  my $ref = \$ns->{ $_[1] };
  return unless ref $ref;
  require Scalar::Util;
  return unless Scalar::Util::reftype($ref) eq 'GLOB';
  require B;
  my $sv = B::svref_2object($ref)->SV;
  ## no critic (ProhibitPackageVars)
  return 1 if $sv->isa('B::SV') || ( $sv->isa('B::SPECIAL') && $B::specialsv_name[ ${$sv} ] ne 'Nullsv' );
  return;
}


sub get_debug_value {
  my $full_name = $_[0]->full_value_name;
  return $_[0]->is_env_debugging if not defined $full_name;
  return do {
    no strict 'refs';
    return ${$full_name};
  };
}


sub inject_debug_value {
  my $full_name = $_[0]->full_value_name;
  return if not defined $full_name;
  my $value = $_[0]->is_env_debugging;
  if ( _has_value( $_[0]->into, $_[0]->value_name ) ) {
    $value = $_[0]->get_debug_value;
  }
  my $ro = $value;
  if ( not $_[0]->runtime_switchable ) {
    Readonly::Scalar $ro, $value;
  }
  return do {
    no strict 'refs';
    *{$full_name} = \$ro;
  };
}

sub _wrap_debug_sub_switchable {
  my $full_name = $_[0]->full_sub_name;
  return if not defined $full_name;
  my $full_value_name  = $_[0]->full_value_name;
  my $is_env_debugging = $_[0]->is_env_debugging;
  my $debug_sub;
  if ( not defined $full_value_name and not $is_env_debugging ) {
    return sub { };
  }
  my $real_debug = $_[0]->debug_sub;
  return sub {
    {
      no strict 'refs';
      return unless ${$full_value_name};
    }
    goto $real_debug;
  };
}

sub _wrap_debug_sub_frozen {
  my $full_name = $_[0]->full_sub_name;
  return if not defined $full_name;
  my $debug_sub;
  if ( not $_[0]->get_debug_value ) {
    return sub { };
  }
  return $_[0]->debug_sub;
}


sub inject_debug_sub {
  my $code;
  if ( $_[0]->runtime_switchable ) {
    $code = $_[0]->_wrap_debug_sub_switchable;
  }
  else {
    $code = $_[0]->_wrap_debug_sub_frozen;
  }
  my $full_name = $_[0]->full_sub_name;
  return do {
    no strict 'refs';
    *{$full_name} = $code;
  };

}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Package::Debug::Object - Object oriented guts to Package::Debug

=head1 VERSION

version 0.1.0

=head1 METHODS

=head2 C<new>

    my $object = Package::Debug::Object->new(%args);

=head2 C<debug_style>

=head2 C<set_debug_style>

=head2 C<env_key_aliases>

=head2 C<set_env_key_aliases>

=head2 C<env_key_prefix_style>

=head2 C<set_env_key_prefix_style>

=head2 C<env_key_style>

=head2 C<set_env_key_style>

=head2 C<full_sub_name>

=head2 C<set_full_sub_name>

=head2 C<full_value_name>

=head2 C<set_full_value_name>

=head2 C<into>

=head2 C<set_into>

=head2 C<into_level>

=head2 C<set_into_level>

=head2 C<sub_name>

=head2 C<set_sub_name>

=head2 C<value_name>

=head2 C<set_value_name>

=head2 C<env_key>

=head2 C<set_env_key>

=head2 C<env_key_prefix>

=head2 C<set_env_key_prefix>

=head2 C<debug_sub>

=head2 C<set_debug_sub>

=head2 C<log_prefix_style>

=head2 C<set_log_prefix_style>

=head2 C<log_prefix>

=head2 C<set_log_prefix>

=head2 C<is_env_debugging>

=head2 C<set_is_env_debugging>

=head2 C<set_runtime_switchable>

=head2 C<runtime_switchable>

=head2 C<auto_set_into>

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

=head2 C<debug_prefixed_lines>

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

=head2 C<debug_verbatim>

This Debug implementation returns a C<DEBUG> sub that simply
passes all parameters to C<< *STDERR->print >>, as long as debugging is turned on.

    my $code = $object->debug_verbatim;
    $code->( $message );

=head2 C<env_key_from_package>

This C<env_key_style> simply appends C<_DEBUG> to the C<env_key_prefix>

    my $key = $object->env_key_from_package;

=head2 C<env_key_prefix_from_package>

This L<< C<env_key_prefix_style>|/env_prefix_style >> converts L<< C<into>|/into >> to a useful C<%ENV> name.

    Hello::World::Bar -> HELLO_WORLD_BAR

Usage:

    my $prefix = $object->env_key_prefix_from_package;

=head2 C<log_prefix_from_package_short>

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

=head2 C<log_prefix_from_package_long>

This L<< C<log_prefix_style>|/log_prefix_style >> simply returns C<into> as-is.

Usage:

    my $prefix = $object->log_prefix_from_package_long;

=head2 C<get_debug_value>

Returns the "are we debugging right now" value.

    if ( $object->get_debug_value ) {
        print "DEBUGGING IS ON!"
    }

=head2 C<inject_debug_value>

Optimistically injects the desired C<$DEBUG> symbol into the package determined by C<full_value_name>.

Preserves the existing value if such a symbol already exists.

    $object->inject_debug_value();

=head2 C<inject_debug_sub>

Injects the desired code reference C<DEBUG> symbol into the package determined by C<full_sub_name>

    $object->inject_debug_sub();

=head1 ATTRIBUTES

=head2 C<debug_style>

The debug printing style to use.

    'prefixed_lines'

See L<< C<debug_styles>|/debug_styles >>

=head2 C<env_key_aliases>

A C<[]> of C<%ENV> keys that also should trigger debugging on this package.

    []

=head2 C<env_key_prefix_style>

The mechanism for determining the C<prefix> for the C<%ENV> key.

    'default'

See  L<< C<env_key_prefix_styles>|/env_key_prefix_styles >>

=head2 C<env_key_style>

The mechanism for determining the final C<%ENV> key for turning on debug.

    'default'

See L<< C<env_key_styles>|/env_key_styles >>

=head2 C<full_sub_name>

Fully qualified name of the C<sub> that will be injected to implement debugging.

Default is:

    <into> . '::' . <sub_name>

Or

    undef

If C<sub_name> is C<undef>

See L<< C<into>|/into >> and L<< C<sub_name>|/sub_name >>

=head2 C<full_value_name>

Fully qualified name of the C<value> that will be injected to implement debugging control.

Default is:

    <into> . '::' . <value_name>

Or

    undef

If C<value_name> is C<undef>

See L<< C<into>|/into >> and L<< C<value_name>|/value_name >>

=head2 C<into>

The package we're injecting into.

B<IMPORTANT>: This field cannot vivify itself and be expected to work.

Because much code in this module depends on this field,
if this field is B<NOT> populated explicitly by the user, its likely
to increase the stack depth, invalidating any value if L<< C<into_level>|/into_level >> that was specified.

See L<< C<auto_set_into>|/auto_set_into >>

=head2 C<into_level>

The number of levels up to look for C<into>

Note, that this value is expected to be provided by a consuming class somewhere, and is expected to be
simply passed down from a user.

See  L<< C<auto_set_into>|/auto_set_into >> for how to set C<into> sanely.

=head2 C<sub_name>

The name of the C<CODEREF> that will be installed into C<into>

    'DEBUG'

=head2 C<value_name>

The name of the C<$SCALAR> that will be installed into C<into>

    'DEBUG' ## $DEBUG

=head2 C<env_key>

The name of the primary C<%ENV> key that controls debugging of this package.

If unspecified, will be determined by the L<< C<env_key_style>|/env_key_style >>

Usually, this will be something like

    <env_key_prefix>_DEBUG

And where C<env_key_prefix> is factory,

    <magictranslation(uc(into))>_DEBUG

Aka:

    SOME_PACKAGE_NAME_DEBUG

=head2 C<env_key_prefix>

The name of the B<PREFIX> to use for C<%ENV> keys for this package.

If unspecified, will be determined by the L<< C<env_key_prefix_style>|/env_key_prefix_style >>

Usually, this will be something like

    <magictranslation(uc(into))>

Aka:

    SOME_PACKAGE_NAME

=head2 C<debug_sub>

The actual code ref to install to do the real debugging work.

This is mostly an implementation detail, but if you were truly insane, you could pass a custom C<coderef>
to construction, and it would install the C<coderef> you passed instead of the one we generate.

Generated using L<< C<debug_style>|/debug_style >>

=head2 C<log_prefix_style>

The default style to use for C<log_prefix>.

If not set, defaults to the value of C<$ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE}> if it exists,
or simply C<'short'> if it does not.

See L<< C<log_prefix_styles>|/log_prefix_styles >>

=head2 C<log_prefix>

The string to prefix to log messages for debug implementations which use prefixes.

If not specified, will be generated from the style specified by L<< C<log_prefix_style>|/log_prefix_style >>

Which will be usually something like

    Foo::Package::Bar # 'long'
    F:P::Bar          # 'short'

=head2 C<is_env_debugging>

The determination as to whether or not the C<%ENV> indicates debugging should be enabled.

Will always be C<true> if C<$ENV{PACKAGE_DEBUG_ALL}>

And will be C<true> if either L<< C<env_key>|/env_key >> or one of L<< C<env_key_aliases>|/env_key_aliases >>
is C<true>.

B<NOTE:> This value I<BINDS> the first time it is evaluated, so for granular control of debugging at run-time,
you should not be lexically changing C<%ENV>.

Instead, you should be modifying the value of C<$My::Package::Name::DEBUG>

=head2 C<runtime_switchable>

This controls whether or not

    $YourPackage::DEBUG

Should be modifiable at run-time.

If it is C<true>, then a performance penalty will occur, because the C<DEBUG> sub can no longer be
a complete C<no-op>, due to needing to check the value of this variable every time it is called.

=head1 STYLES

=head2 C<env_key_styles>

=head3 C<default>

Uses L<< C<env_key_from_package>|/env_key_from_package >>

=head2 C<env_key_prefix_styles>

=head3 C<default>

Uses L<< C<env_key_prefix_from_package>|/env_key_prefix_from_package >>

=head2 C<log_prefix_styles>

=head3 C<short>

Uses L<< C<log_prefix_from_package_short>|/log_prefix_from_package_short >>

=head3 C<long>

Uses L<< C<log_prefix_from_package_long>|/log_prefix_from_package_long >>

=head2 C<debug_styles>

=head3 C<prefixed_lines>

Uses L<< C<debug_prefixed_lines>|/debug_prefixed_lines >>

=head3 C<verbatim>

Uses L<< C<debug_verbatim>|/debug_verbatim >>

=head1 PRIVATE FUNCTIONS

=head2 C<_has>

Internal minimalist lazy-build w/setter generator

    _has $name => $coderef;

is roughly equivalent to L<< C<Moo>|Moo >>'s

    has $name => (
        is => ro =>,
        lazy => 1,
        writer => "set_$name",
        builder => $coderef
    );

C<$coderef> can be a C<string>, in which case it will be bolted
on slightly more efficiently, using

    sub Package::Debug::Object::namehere {
            the_actual_code_here
    }

Instead of

    *Package::Debug::Object::namehere = $builder

=head2 C<_has_value>

Internal function shredded from guts of L<<< C<< Package::Stash::B<PP> >>|Package::Stash::PP >>>, for the purpose
of determining if a given package already has a specific value defined or not.

This is mostly to facilitate this:

    BEGIN {
        $Some::Package::DEBUG = 1;
    }
    use Some::Package;

This way, we don't stomp over that value.

Usage:

    if ( _has_value( $package, $variable_name ) ) {
        ...
    }

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Package::Debug::Object",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
