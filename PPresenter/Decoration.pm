# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Decoration;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant defaults =>
{ type         => 'decoration'
, -backgroundBounds => [ qw/5% 5% 5% 5%/ ] #left-top-right-bottom
, -bgcolor     => undef
, -fgcolor     => undef
, -bdcolor     => undef
, -backdrop    => undef

, devices      =>
  # device       bgcolor      fgcolor   bdcolor  backdrop?
  { lcd     => [ 'dark blue', 'yellow', 'black', 1         ]
  , beamer  => [ 'white',     'black',  'gray',  0         ]
  , printer => [ 'white',     'black',  'gray',  0         ]
  }

, -nestImages  => ['640x480', 'greenball.gif', 'redball.gif', 'purpleball.gif' ]
};

sub InitObject()
{   my $deco = shift;

    $deco->check_nestImages(@{$deco->{-nestImages}});
    $deco;
}

sub check_nestImages($@)
{   my ($deco, $geom) = (shift, shift);

    if(defined $geom)
    {   foreach (@_)
        {   next unless ref $_;
            next if $_->isa('PPresenter::Image::Magick');
            # Photo objects are already sized.
            die "-nestImages geometry only on filenames and Magick objects.\n";
        }
    }
    else
    {   foreach (@_)
        {   next unless ref @_;
            next if $_->isa('PPresenter::Image');
            die "-nestImages wants filenames or PPresenter::Image objects.\n";
        }
    }
}

sub addDevice($$$$)
{   my $deco = shift;
    unshift @{$deco->{devices}}, [ @_ ];
    $deco;
}

sub hasBackdrop($)
{   my ($deco,$device) = @_;

    return $deco->{-backdrop}
        if defined $deco->{-backdrop};

    my $spec = $deco->{devices}{$device} || undef;
    die "Undefined device $device.\n" unless defined $spec;
    $spec->[3];
}

sub getBounds()   { @{$_[0]->{-backgroundBounds}} }

sub getColor($$)
{   my ($deco, $device, $name) = @_;

    my $NAME = uc $name;
    my $spec = $deco->{devices}{$device} || undef;
    die "Undefined device $device\n" unless defined $spec;

    return $deco->{-bgcolor} || $spec->[0] if $NAME eq 'BGCOLOR';
    return $deco->{-fgcolor} || $spec->[1] if $NAME eq 'FGCOLOR';
    return $deco->{-bdcolor} || $spec->[2] if $NAME eq 'BDCOLOR';

    $name;
}

sub getNestImageDef($$)
{   my ($deco, $nest) = @_;

    my $nr_images = @{$deco->{-nestImages}}-1;
    $nest = $nr_images-1 if $nest >= $nr_images;

    @{$deco->{-nestImages}}[0,$nest+1];
}

# Working with id's avoids reproduction of a background when this
# does not change.  This may smoothen the presentation.

sub makeBackground($$$$)
{   my ($deco, $id, $show, $slide, $viewport) = @_;

    my $new_id = $deco->createId($viewport);
    return $id if defined $id && $new_id eq $id;  # No change in background.

    $deco->removeBackground($viewport, $id)
         ->createBackground($show,$slide,$viewport,$new_id);

    return $new_id;
}

sub removeBackground($$)
{   my ($deco, $viewport, $id) = @_;
    # All background objects are tagged with id.
    $viewport->getCanvas->delete($id);
    $deco;
}

1;
