# Copyright (C) 1999, Free Software Foundation Inc.

# Viewport
#
# This packages drives the display on one viewport of the slide-show.
#

package PPresenter::Viewport;

use strict;
use PPresenter::Object;
use base 'PPresenter::Object';

use Tk;

use constant defaults =>
{ -name               => 'default'
, -aliases            => undef

, -display            => $ENV{DISPLAY}
, -device             => 'lcd'
, -geometry           => undef
, -resizable          => 0

, -hasControl         => undef
, -showSlideNotes     => 0
, -style              => undef
, show                => undef
};

sub InitObject()
{   my ($viewport) = shift;
    my $show = $viewport->{show};

    $viewport->SUPER::InitObject;

    $viewport->{selected_style}
        = defined $viewport->{-style}
        ? $show->find(style=>$viewport->{-style})
        : $viewport->showSlideNotes
        ? $show->find(style=>'slidenotes')
        : $show->find(style=>'SELECTED');

    my $screen = MainWindow->new(-screen => $viewport->{-display});
    my $geometry
        = $viewport->{-geometry}
        || $show->{-geometry}
        || sprintf("%dx%d+0+0", $screen->screenwidth, $screen->screenheight);

    $screen->geometry($geometry);

    $screen->resizable(0,0) unless $viewport->{-resizable};
    $screen->appname('PP');

    $viewport->{screen} = $screen;
    $viewport->{playfield} = $screen->Canvas->pack
        (-fill => 'both', -expand => 1);

    $screen->waitVisibility;
    $viewport;
}

sub getGeometry() {$_[0]->{-geometry}}
sub getScreen()   {$_[0]->{screen}}
sub getCanvas()   {$_[0]->{playfield}}
sub getStyle()    {$_[0]->{selected_style}}
sub getDevice()   {$_[0]->{-device}}
sub getDisplay()  {$_[0]->{-display}}
sub getScreenId() {$_[0]->{screen}->id}
sub getCanvasId() {$_[0]->{playfield}->id}

sub iconify()     {$_[0]->{screen}->iconify}
sub withdraw()    {$_[0]->{screen}->withdraw}
sub raise(@)      {shift->{screen}->raise(@_)}
sub sync(@)       {shift->{screen}->update(@_)}

#
# Selections
#

sub select($$;)
{   my ($viewport, $type, $name) = @_;

    return $viewport->{selected_style} = $viewport->find(style => $name)
        if $type eq 'style';

    $viewport->{selected_style}->select($type, $name);
}

sub find($$)
{   my ($viewport, $type, $name) = @_;

    return $viewport->{selected_style}
        if $type eq 'style' && $name eq 'SELECTED';

    return $viewport->{show}->find($type, $name)
        if $type eq 'style';

    $viewport->{selected_style}->find($type, $name)
}

sub getStyleElems($)
{   my ($viewport, $slide, $flags) = @_;
    my $style = exists $flags->{style}
              ? $viewport->{show}->find(style => $flags->{style})
              : $viewport->{selected_style};
    $style->getStyleElems($slide, $flags);
}

sub getFont(@)
{   my $viewport = shift;
    $viewport->find(fontset => 'SELECTED')->getFont($viewport, @_);
}

#
# Slides
#

sub setSlide($$)
{   my ($viewport,$slide,$newtag) = @_;
    my $tag = $viewport->{current_tag};
    $viewport->getCanvas->delete($tag) if defined $tag;
    $viewport->{current_slide} = $slide;
    $viewport->{current_tag}   = $newtag;
}

sub packViewport(;)
{   $_[0]->{playfield}
         ->pack(-side => 'top', -expand => 1, -fill => 'both');
}

sub showSlideNotes    {$_[0]->{-showSlideNotes}}
sub hasControl        { 0 }

sub getBackgroundId() {$_[0]->{background_id}}
sub setBackgroundId() {$_[0]->{background_id} = $_[1]}

#
# Program
#

sub startProgram(@)
{   my ($viewport, $program) = @_;
    $viewport->{program} = $program;
    $program->start;
    $viewport;
}

sub removeProgram(;)
{   my $viewport = shift;
    return unless $viewport->{program};
    $viewport->{program}->removeProgram;
    undef $viewport->{program};
    $viewport;
}

sub nextProgramPhase($)   {$_[0]->{program}->nextPhase}

#
# Geometry
#

sub getCanvasDimensions()
{   my $canvas = shift->{playfield};
    ($canvas->width, $canvas->height);
}

sub screenMessures()
{   my $viewport = shift;

    unless(defined $viewport->{width})
    {   my $screen = $viewport->getScreen;
        @$viewport{'width','height'} = ($screen->width, $screen->height);
    }

    return @$viewport{'width','height'};
}

sub findClosestsGeometry($@;)
{   my $viewport = shift;

    my ($width, $height) = $viewport->screenMessures;
    my ($best, $prefer);

    foreach (@_)
    {   my ($w, $h) = split /x/;
        my $distance = ($width-$w)*($width-$w)+($height-$h)*($height-$h);
        next if defined $best && $best < $distance;

        $best = $distance;
        $prefer = $_;
    }

    return $prefer;
}

sub getGeometryScaling($;$)    # args is (geometry) or (width,height)
{   my $viewport = shift;
    my ($w, $h)  = (@_ == 1 ? $_[0] =~ m/(\d+)x(\d+)/ : @_);
 
    my ($width, $height) = $viewport->screenMessures;
    my $twodim = ($width*$height) / ($w*$h);
    return sqrt($twodim);
}

sub Photo(@) {shift->getCanvas->Photo(@_)}

1;
