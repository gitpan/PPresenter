# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Fontset;

use strict;
use PPresenter::StyleElem;
use base 'PPresenter::StyleElem';

use constant defaults =>
{ type          => 'fontset'
, -fontLabels   => [ qw/pico  micro tiny small   normal
                      large big   huge massive giant/]

, -rawFontSizes => [ '1280x1024'
      , 10,  30,  40,  50,  60
      , 75, 100, 150, 200, 300 ]

, -fontSizes    => undef
, -fixedFont    => undef
, -proportionalFont => undef
};

sub InitObject()
{   my $fontset = shift;

    return $fontset
        unless defined $fontset->{-fontSizes};

    my $labels = @{$fontset->{-fontLabels}};
    die "A list of absolute fontsizes must be $labels long.\n"
        if $labels != @{$fontset->{-fontSizes}};

    $fontset;
}

sub getFontSizes($$)
{   my ($fontset, $viewport) = @_;
    return $fontset->{-fontSizes} if defined $fontset->{-fontSizes};

    my ($width,$height) = $viewport->screenMessures;
    my $label    = "fontSizes_${width}x${height}";

    @{$fontset->{$label}}
        = $fontset->calcRealFontSizes($viewport, $fontset->{-rawFontSizes})
            unless defined $fontset->{$label};

    $fontset->{$label};
}

sub sizeToPixels($$)
{   my ($fontset, $viewport, $size) = @_;
    return $1 if $size =~ /^\s*(\d+)p$/;
    $fontset->getFontSizes($viewport)->[$size];
}

# A fontset will overrule this when there are only specific values allowed.
sub calcRealFontSizes($$$)
{   my ($fontset, $viewport, $raw) = @_;
    @_ = @$raw;
    my $scaling = $viewport->getGeometryScaling(shift);
    map {int($_*$scaling)} @_;
}

sub findFontSize($$$)
{   my ($fontset, $viewport, $base, $size) = @_;

    return $size if $size =~ /^\s*\d+\s*$/;        # is a number
    return $size if $size =~ /\s*\d+p$/;           # size in pixels

    my $relative_size;
    if($size =~ /^\s*(\+|\-)\d+\s*$/ )
    {   # is a relative number
        $relative_size = $base + $size;
    }
    else
    {   # Is a fontsize-name
        foreach (@{$fontset->{-fontLabels}})
        {   last if $_ eq $size;
            $relative_size++;
        }
    }

    if($relative_size > @{$fontset->{-fontLabels}})
    {   warn "Cannot find font-size $size.  Back to normal.\n";
        $fontset->translateFontSize($viewport, undef, 'normal');
    }

    $relative_size  = $relative_size < 0 ? 0
            : $relative_size < @{$fontset->{-fontLabels}} ? $relative_size
            : $#{$fontset->{-fontLabels}};

    return $relative_size;
}

sub getFontHeight($)
{   my ($fontset, $font) = @_;
    return $font->fontMetrics('-ascent')
           + $font->fontMetrics('-descent');
}

1;
