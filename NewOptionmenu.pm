# Copyright (c) 1995-1999 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Modified by Andrew Perrin (c) 2000. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Tk::NewOptionmenu;
require Tk::Menubutton;
require Tk::Menu;

use vars qw($VERSION);
$VERSION = '3.020'; # $Id: //depot/Tk8/Tk/Optionmenu.pm#20 $

use base  qw(Tk::Derived Tk::Menubutton);

use strict;

Construct Tk::Widget 'NewOptionmenu';

sub Populate
{
 my ($w,$args) = @_;
 $w->SUPER::Populate($args);
 $args->{-indicatoron} = 1;
 my $var = delete $args->{-textvariable};
 unless (defined $var)
  {
   my $gen = undef;
   $var = \$gen;
  }
 my $menu = $w->menu(-tearoff => 0);
 $w->configure(-textvariable => $var);

 $w->ConfigSpecs(-command => ['CALLBACK',undef,undef,undef],
                 -options => ['METHOD', undef, undef, undef],
		 -variable=> ['METHOD', undef, undef, undef],
		 -font    => [['SELF',$menu], undef, undef, undef],
		 -limittolist => ['PASSIVE', undef, undef, undef],
   -takefocus          => [ qw/SELF takefocus          Takefocus          1/ ],
   -highlightthickness => [ qw/SELF highlightThickness HighlightThickness 1/ ],
   -relief             => [ qw/SELF relief             Relief        raised/ ],

                );

 $w->configure(-variable => delete $args->{-variable});
}

sub setOption
{
 my ($w, $label, $val, $dontstore) = @_;
 $val = $label if @_ == 2;
 my $limit = $w->cget('-limittolist');
 my $check = 0;
 $check = 1 unless defined $w->{options};
 $check = 1 if exists $w->{options}->{$val};
 $check = 1 unless $limit;
 if ($check) {
   my $var = $w->cget(-textvariable);
   $$var = $label;
   unless ($dontstore) {
     $var = $w->cget(-variable);
     $$var = $val if $var;
   }
 }
 $w->Callback(-command => $val);
}

sub addOptions
{
 my $w = shift;
 my $menu = $w->menu;
 my $var = $w->cget(-textvariable);
 my $width = $w->cget('-width');
 while (@_)
  {
   my $val = shift;
   my $label = $val;
   if (ref $val)
    {
     ($label, $val) = @$val;
    }
   my $len = length($label);
   $width = $len if (!defined($width) || $len > $width);
   $menu->command(-label => $label, -command => 
		  [ $w , 'setOption', $label, $val ]);
   if (exists $w->{options}->{$val}) {
     warn 'Overwriting option ', $w->{options}->{$val}, 
       " with $label for value $val" unless $label eq
	 $w->{options}->{$val};
   }
   $w->{options}->{$val} = $label;
  }
 $w->configure('-width' => $width);
}

sub variable {
  my $w = shift;
  if (@_) {
    my $ref = shift;
    return unless ref $ref;
    my $val = $$ref;
    tie $$ref, 'OptionMenuVar', $w, $val;
    $w->{variable} = $ref;
  }
  return $w->{variable};
}

sub options
{
 my ($w,$opts) = @_;
 if (@_ > 1)
  {
   $w->menu->delete(0,'end');
   $w->{options} = {};
   $w->addOptions(@$opts);
  }
 else
  {
   return $w->_cget('-options');
  }
}

package OptionMenuVar;

sub TIESCALAR {
  my($class, $w, $init) = @_;
  my $self = {};
  $self->{widget} = $w;
  $w->bind('<Destroy>',sub {
	     untie $ {$w->{variable}}
	   });
  bless $self, $class;
  $self->STORE($init) if defined $init;
  return $self;
}

sub STORE {
  my ($self, $value) = @_;
  if (defined $self->{widget}->{options}) {
    my $val = $self->{widget}->{options}->{$value};
    if (defined $val) {
      $self->{widget}->setOption($val, $value, 1);
      $self->{widget}->{stored} = $value;
      $self->{widget}->{display} = $val;
    } else {
      my $limit = $self->{widget}->cget('-limittolist');
      if ($limit) {
	warn "Illegal value $value submitted to Optionmenu";
	if (defined $self->{widget}->{stored}) {
	  $self->{widget}->setOption($self->{widget}->{display},
				     $self->{widget}->{stored},
				     1);
	} else {
	  $self->{widget}->setOption('','',1);
	}
      } else {
	$self->{widget}->{stored} = $value;
	$self->{widget}->{display} = $value;
	$self->{widget}->setOption($value, $value, 1);
      }
    }
  } else {
    my $limit = $self->{widget}->cget('-limittolist');
    warn "Limit to list ignored because no option list provided"
      if $limit;
    $self->{widget}->{stored} = $value;
    $self->{widget}->{display} = $value;
    $self->{widget}->setOption($value, $value, 1);
  }
}

sub FETCH {
  my $self = shift;
  return $self->{widget}->{stored};
}

1;

__END__

=cut

