# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Export::IM_Images;

# This module has it's own Tk interface, but is also extended
# by more complex objects.

use strict;
use PPresenter::Export;
use base 'PPresenter::Export';

use Tk;
use Tk::Dialog;
use Image::Magick;

use constant defaults =>
{ -name        => 'Images with ImageMagick'
, -aliases     => [ 'images', 'im images', 'IM images', 'IM Images' ]

, -outputDir   => 'slideImages'
};

sub view2image($$)
{   my ($export, $show, $opts) = @_;

    print Presenter::TRACE "Dumping image for $opts->{view}.\n";

    my $image = $export->getWindowImage($show, $opts);
    return unless defined $image;

    $export->polishImage($image);
    $image;
}

sub readImage($)
{   my ($export, $file) = @_;

    my $img   = Image::Magick->new;
    my $error = $img->Read($file);
    return $img unless $error;

    print "Magick error on reading image from $file: $error\n";
    undef;
}

sub polishImage($)
{   my ($export, $img) =@_;

    $img->Zoom(geometry => "$export->{-imageWidth}x10000")
        if defined $export->{-imageWidth} && $export->{-imageWidth} != 0;

    my $format = lc $export->{-imageFormat};

    $img->Set( magick    => $format
             , quality   => $export->{-imageQuality}
             , interlace => ($format eq 'png' ? 'Plane' : 'Line')
             );

    $export;
}

sub writeImage($$)
{   my ($export, $image, $file) = @_;

    $image->Set(filename => $file);
    $image->Write;
    $export;
}

sub getDimensions($)
{   my ($export, $image) = @_;
    $image->Get('width', 'height');
}

#
# The user interface to this module.
#

sub getPopup($$)
{   my ($export, $show, $screen) = @_;
    return $export->{popup}
        if exists $export->{popup};

    $export->{popup} = my $popup = MainWindow->new(-screen => $screen
    , -title => 'Export images'
    );
    $popup->withdraw;

    my $vp = $export->tkViewportSettings($show, $popup);
    my $im = $export->tkImageSettings($show, $popup);

    my $options = $popup->Frame;
    $options->Label
    ( -text     => 'export'
    , -anchor   => 'e'
    )->grid($export->tkSlideSelector($popup), -sticky => 'ew');

    $options->Label
    ( -text     => 'output dir'
    , -anchor   => 'e'
    )->grid($options->Entry(-textvariable => \$export->{-outputDir})
           , -sticky => 'ew');

    my $commands = $popup->Frame;
    $commands->Button
    ( -text      => 'Export'
    , -relief    => 'ridge'
    , -command   => sub {$export->export($show, $popup)}
    )->grid($commands->Button
       ( -text      => 'Cancel'
       , -relief    => 'sunken'
       , -command   => sub {$popup->withdraw}
       )
    , -padx => 10, -pady => 10
    );

    $im      ->grid(-sticky => 'ew');
    $options ->grid(-sticky => 'ew');
    $vp      ->grid(-sticky => 'ew') if defined $vp;
    $commands->grid(-columnspan => 2, -sticky => 'ew');

    return $popup;
}

sub export($$)
{   my ($export, $show, $popup) = @_;

    $export->createDirectory($popup, $export->{-outputDir}) || return;
    $popup->withdraw;

    return if 'Cancel' eq $popup->Dialog
    (   -title    => 'Starting Export'
    ,   -text     => <<TEXT
Starting the export of you presentation as images.

Each of the slides will be shown, and then has its picture taken.

Do not touch your mouse while the processing is going on.
TEXT
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK', 'Cancel' ]
    )->Show;

    print Presenter::TRACE "Exporting slides to images started.\n";

    foreach ($export->selectedSlides($show))
    {   $export->makeSlideExports
        ( $show, $_
        , [ $export->selectedViewports ]
        , [ sub {shift->export_image($show, @_)}, $export ]
        )
    }

    $popup->Dialog
    (   -title    => 'Ready'
    ,   -text     => 'The images are ready.'
    ,   -bitmap   => 'info'
    ,   -buttons  => [ 'OK' ]
    )->Show;

    print Presenter::TRACE "Exporting slides to images ready.\n";

    $export;
}

sub export_image($$)
{   my ($export, $show, $opts) = @_;
    my ($viewport, $slide, $view, $window, $display, $borders)
        = @$opts{qw/viewport slide view window_id display borders/};

    my $dir    = $export->{-outputDir};
    my $id     = sprintf "%03d", $slide->getNumber;
    my $format = lc $export->{-imageFormat};
    my $file   = "$dir/$id-$viewport.$format";

    my $image  = $export->view2image($show, $opts);
    $export->writeImage($image, $file) if $image;
}

1;

