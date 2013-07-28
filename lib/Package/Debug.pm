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
  my $object = Package::Debug::Object->new(%args);
  $object->auto_set_into(1);
  if ( not $object->is_env_debugging ) {
    $object->inject_debug_value(undef);
    $object->inject_debug_sub( sub { } );
    return;
  }
  if ( not $args{build_debug_sub} ) {
    $args{build_debug_sub} = sub {
      my (%parms) = @_;
      return sub {
        my (@message) = @_;
        for my $line (@message) {
          *STDERR->print( '[' . $object->log_prefix . '] ' ) if defined $object->log_prefix;
          *STDERR->print($line);
          *STDERR->print("\n");
        }
      };
    };
  }
  if ( not $args{debug_sub} ) {
    $args{debug_sub} = $args{build_debug_sub}->(%args);
  }
  $object->inject_debug_value(1);
  $object->inject_debug_sub( $args{debug_sub} );

}
{
  package    # hide from pause and friends.
    Package::Debug::Object;

  my %env_key_styles        = ( default => 'env_key_from_package', );
  my %env_key_prefix_styles = ( default => 'env_key_prefix_from_package', );
  my %log_prefix_styles     = (
    short => 'log_prefix_from_package_short',
    long  => 'log_prefix_from_package_long',
  );

  sub new {
    my ( $self, %args ) = @_;
    return bless \%args, $self;
  }

  sub has {
    my ( $name, $builder ) = @_;
    local $@;

    eval qq[
        sub $name { 
            return \$_[0]->{$name} if exists \$_[0]->{$name};
            return ( \$_[0]->{$name} = \$builder->(\@_) );
        }; 
        1;
    ] or die "Can't compile accessor $name $@";
    eval qq[
        sub set_$name {
            \$_[0]->{$name} = \$_[1];
            return \$_[0];
        };
        1;
    ] or die "Can't compile accessor set_$name $@";
  }

  has into_level    => sub { 0 };
  has into          => sub { die 'Cannot vivify ->into automatically, pass to constructor or ->set_into() or ->auto_set_into()' };
  has package       => sub { $_[0]->into };
  has env_key_style => sub { 'default' };
  has env_key_prefix_style => sub { 'default' };
  has env_key_aliases      => sub { [] };
  has value_name           => sub { 'DEBUG' };
  has sub_name             => sub { 'DEBUG' };

  has env_key => sub {
    my $style = $_[0]->env_key_style;
    if ( not exists $env_key_styles{$style} ) {
      die "No such env_key_style $style, options are @{ keys %env_key_styles }";
    }
    my $method = $env_key_styles{$style};
    return $_[0]->$method();
  };

  has env_key_prefix => sub {
    my $style = $_[0]->env_key_prefix_style;
    if ( not exists $env_key_prefix_styles{$style} ) {
      die "No such env_key_prefix_style $style, options are @{ keys %env_key_prefix_styles }";
    }
    my $method = $env_key_prefix_styles{$style};
    return $_[0]->$method();
  };

  has log_prefix_style => sub {
    if ( $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE} ) {
      return $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE};
    }
    return 'short';
  };

  has log_prefix => sub {
    my $style = $_[0]->log_prefix_style;
    if ( not exists $log_prefix_styles{$style} ) {
      die "Unknown prefix style $style, should be one of @{ keys %log_prefix_styles }";
    }
    my $method = $log_prefix_styles{$style};
    $_[0]->$method();
  };

  has is_env_debugging => sub {
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

  sub inject_debug_value {
    return if not defined $_[0]->value_name;
    no strict 'refs';
    *{ $_[0]->package . '::' . $_[0]->value_name } = \$_[1];
  }

  sub inject_debug_sub {
    return if not defined $_[0]->sub_name;
    no strict 'refs';
    *{ $_[0]->package . '::' . $_[0]->sub_name } = $_[1];
  }

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
