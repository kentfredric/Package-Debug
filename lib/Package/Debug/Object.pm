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


my %env_key_styles        = ( default => 'env_key_from_package', );


my %env_key_prefix_styles = ( default => 'env_key_prefix_from_package', );


my %log_prefix_styles     = (
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


sub _has {
  my ( $name, $builder ) = @_;
  local $@;
  my $package = __PACKAGE__;
  my $builder_code;
  if ( ref $builder ) {
    $builder_code = "*${package}::_build_${name} = \$builder;";
  }
  else {
    $builder_code = "sub ${package}::_build_${name} { $builder }";
  }

  my $code = qq[
        $builder_code;
        sub ${package}::${name} {
            return \$_[0]->{$name} if exists \$_[0]->{$name};
            return ( \$_[0]->{$name} = \$_[0]->_build_${name}(splice \@_,1) );
        };
        sub ${package}::set_${name} {
            \$_[0]->{$name} = \$_[1]; return \$_[0];
        };
    ];
  eval $code;
  die "Compiling code << sub { $code } >> failed. $@" if $@;
}


_has debug_style          => q[ 'prefixed_lines' ];


_has env_key_aliases      => q[ []  ];


_has env_key_prefix_style => q[ 'default' ];
_has env_key_style        => q[ 'default' ];
_has full_sub_name        => q[ return if not $_[0]->sub_name   ; $_[0]->package . '::' . $_[0]->sub_name   ];
_has full_value_name      => q[ return if not $_[0]->value_name ; $_[0]->package . '::' . $_[0]->value_name ];
_has into       => q[ die 'Cannot vivify ->into automatically, pass to constructor or ->set_into() or ->auto_set_into()' ];
_has into_level => q[ 0 ];
_has package    => q[ $_[0]->into ];
_has sub_name   => q[ 'DEBUG' ];
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
  return undef;
};

sub auto_set_into {
  my ( $self, $add ) = @_;
  $_[0]->{into} = [ caller( $self->into_level + $add ) ]->[0];
}

sub debug_prefixed_lines {
  my $self = shift;
  return sub {
    return unless $self->get_debug_value;
    my (@message) = @_;
    for my $line (@message) {
      *STDERR->print( '[' . $self->log_prefix . '] ' ) if defined $self->log_prefix;
      *STDERR->print($line);
      *STDERR->print("\n");
    }
  };
}

sub env_key_from_package {
  return $_[0]->env_key_prefix() . '_DEBUG';
}

sub env_key_prefix_from_package {
  my $package = $_[0]->package;
  $package =~ s/::/_/g;
  return uc($package);
}

sub log_prefix_from_package_short {
  my $package = $_[0]->package;
  if ( ( length $package ) < 10 ) {
    return $package;
  }
  my (@tokens) = split /::/, $package;
  my ($last) = pop @tokens;
  for (@tokens) {
    if ( $_ =~ /[A-Z]/ ) {
      $_ =~ s/[a-z]+//g;
      next;
    }
    $_ =~ s/^(.).*/$1/;
  }
  my ($left) = join q{:}, @tokens;
  return $left . '::' . $last;
}

sub log_prefix_from_package_long {
  return $_[0]->package;
}

sub _has_value {
  my $ns = do { no strict 'refs'; \%{ $_[0] . '::' } };
  return if not exists $ns->{ $_[1] };
  my $ref = \$ns->{ $_[1] };
  return unless ref $ref;
  require Scalar::Util;
  return unless Scalar::Util::reftype($ref) eq 'GLOB';
  require B;
  my $sv = B::svref_2object($ref)->SV;
  return 1 if $sv->isa('B::SV') || ( $sv->isa('B::SPECIAL') && $B::specialsv_name[$$sv] ne 'Nullsv' );
  return;
}

sub get_debug_value {
  return $_[0]->is_env_debugging if not defined $_[0]->full_value_name;
  return do {
    no strict 'refs';
    return ${ $_[0]->full_value_name };
  };
}

sub inject_debug_value {
  return if not defined $_[0]->full_value_name;
  my $value = $_[0]->is_env_debugging;
  if ( _has_value( $_[0]->package, $_[0]->value_name ) ) {
    $value = $_[0]->get_debug_value;
  }
  return do {
    no strict 'refs';
    *{ $_[0]->full_value_name } = \$value;
  };
}

sub inject_debug_sub {
  return if not defined $_[0]->full_sub_name;
  my $debug_sub = $_[0]->debug_sub;
  return do {
    no strict 'refs';
    *{ $_[0]->full_sub_name } = $debug_sub;
  };
}

1

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

=head1 ATTRIBUTES

=head2 C<debug_style>

The debug printing style to use.

    'prefixed_lines'

See L</debug_styles>

=head2 C<env_key_aliases>

A C<[]> of C<$ENV> keys that also should trigger debugging on this package.

    []

=head2 C<env_key_prefix_style>

The mechanism for determing the C<prefix> for the C<$ENV> key. 

    'default'

See L</env_key_prefix_styles>

=head1 STYLES

=head2 C<env_key_styles>

=head3 C<default>

Uses L</env_key_from_package>

=head2 C<env_key_prefix_styles>

=head3 C<default>

Uses L</env_key_prefix_from_package>

=head2 C<log_prefix_styles>

=head3 C<short>

Uses L</log_prefix_from_package_short>

=head3 C<long>

Uses L</log_prefix_from_package_long>

=head2 C<debug_styles>

=head3 C<prefixed_lines>

Uses L</debug_prefixed_lines>

=head3 C<verbatim>

Uses L</debug_verbatim>

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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
