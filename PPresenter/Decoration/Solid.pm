# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Decoration::Solid;

use strict;
use PPresenter::Decoration;
use base 'PPresenter::Decoration';

use constant defaults =>
{ -name        => 'solid'
, -aliases     => [ 'default' ]
};

sub createId($)
{   my ($deco,$viewport) = @_;
    return "solid_".$deco->getColor($viewport->getDevice,'BGCOLOR');
}

sub createBackground($$$$)
{   my ($deco, $show, $slide, $viewport, $id) = @_;
    $viewport->getCanvas->configure
        ( -background => $deco->getColor($viewport->getDevice,'BGCOLOR')
        );

    # More complex backgrounds will start drawing here, and objects
    # have to be tagged with $id.
}

1;
