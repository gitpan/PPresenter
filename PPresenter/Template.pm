# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Template;

use strict;

use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant defaults =>
{ type            => 'template'
, -showTemplateOutlines => 0
, -place          => undef
# place is an array of arrays, each describing one slide-part.
# Each slide-part description [ x, y, width, height, text ]
# (x,y) (width,height) relative to actual width.  (x,y) is left-top
# unless negative (resp from right or bottom).
# For instance: [ [ 0, 0, 0.3, 0.3, "text" ]
#               , [ qw/-0 -10% 20% 20%/, "more" ] ]

, -titlebarHeight => '15%'
, -areaSeparation => '3%'
};

sub makePart($$)
{   my ($templ, $args, $contents) = @_;

    my ($x, $y, $w, $h, $tag, $dx) = @$args{qw/x y w h id displace_x/};

    # Bound-line for debugging
    my $outline = $templ->{-showTemplateOutlines};
    my $main = $args->{canvas}->createRectangle
        ( $x-$dx, $y, $x-$dx+$w, $y+$h
        , -outline => 'black'
        , -tags    => $tag
        , -width   => $outline
        ) if $outline;

    return $args->{view}->format($args, $contents)
        if ref $contents eq '';
 
    return $args->{canvas}->createImage
        ( $x+ $w/2, $y + $h
        , -image    => $contents
        , -tags     => $tag
        ) if $contents->isa('Tk::Photo');

    warn "Do not understand part of slide \"$args->{slide}\", type ",
         ref $contents, ".\n";
}

sub prepareSlide($)
{   my ($templ, $args) = @_;

    my $canvas = $args->{canvas};
    my ($width, $height) = ($canvas->width, $canvas->height);

    my ($left,$top, $right,$bottom)
        = map {$templ->toPercentage($_)} $args->{view}->getBounds;

    # Place the items.

    return $templ unless defined $templ->{-place};

    # Take-over the place-list from the users-spec: we are going to
    # add things to it, so...
    $templ->{-place} = [ @{$templ->{-place}} ];

    foreach (@{$templ->{-place}})
    {   my ($x,$y, $w,$h, $contents) = @$_;

        my ($rw,$rh) = ((1-$right-$left)*$width,(1-$top-$bottom)*$height);
        $x = $templ->takePercentage($x, $rw);
        $y = $templ->takePercentage($y, $rh);

        @$args{qw/x y w h/} =
        ( int($x+$width*$left+$args->{displace_x}), int($y+$height*$top)
        , int($w*$rw), int($h*$rh)
        );

        $templ->makePart($args, $contents);
    }

    delete @$args{qw/x y w h/};

    return $templ;
}

#
# Export
#

sub makeHTMLTable($)
{   my ($templ, $args) = @_;

    if(@{$templ->{-place}})
    {   warn "Slide $args->{slide} contains placed items: cannot make table.\n"
            if $^W;
        return undef;
    }

    unless ($args->{formatter}->can('toHTML'))
    {   warn "Formatter $args->{formatter} cannot produce HTML.\n";
        return undef;
    }

    $templ->make_HTML_table($args);
}

sub makeHTMLLinear($)
{   my ($templ, $args) = @_;

    unless ($args->{formatter}->can('toHTML'))
    {   warn "Formatter $args->{formatter} cannot produce HTML.\n";
        return undef;
    }

    $templ->make_HTML_linear($args);
}

sub toHTML($$)
{   my ($templ, $args, $content) = @_;
    $args->{formatter}->toHTML($args, $content);
}

1;
