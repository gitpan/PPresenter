# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Image::Magick;

use strict;
use PPresenter::Image;
use base 'PPresenter::Image';

use Image::Magick;
use Tk::Photo;

sub convert($@)     # Convert Image::Magick to PPresenter::Image::Magick
{   my $class = shift;

    my (@magicks, @images);
    push @magicks, @{(shift)}  # magicks are lists of images.
        while @_ && ref $_[0] && $_[0]->isa('Image::Magick');

    foreach (@magicks)
    {   my $img = $class->new
        ( -file   => ($_->Get('filename') || $_->Get('base_filename'))
        , -resize => 0
        , @_
        );

        $img->{source} = $_;
        push @images, $img;

        print Presenter::TRACE "Added Image::Magick image $img.\n";
    }

    @images;
}

sub prepare($$)
{   my ($img, $viewport, $canvas) = @_;

    my $vplabel = "photo_$viewport";
    return $img if exists $img->{$vplabel};

    my $orig;
    if(ref $img->{source})
    {   $orig = $img->{source};
    }
    else
    {   $orig = Image::Magick->new;
        if(my $err = $orig->Read($img->{source}))
        {   print "$err\n";
            return undef;
        }
    }

    my $scaling = $img->getScaling($viewport);

    warn "Poor image quality because $img is enlarged by factor $scaling.\n" if $^W && $scaling > 1.1;

    if($scaling<0.9 || $scaling>1.1)
    {   my ($width, $height) = $orig->Get('width', 'height');

        print Presenter::TRACE
            "Scale image $img with $scaling for $viewport.\n";

        if(my $err = $orig->Zoom( width  => $width*$scaling
                                , height => $height*$scaling))
        {   print "$err\n";
        }
    }

    $img->{$vplabel} = $img->make_photo($orig, $canvas);
    $img;
}

sub make_photo($$)
{   my ($img, $magick, $canvas) = @_;

    $magick->Set(magick => 'xpm');

    $canvas->Photo
      ( -data   => $magick->ImageToBlob
      , -format => 'xpm'
      , -width  => $magick->Get('width')
      , -height => $magick->Get('height')
      );
}

sub show($$$$)
{   my ($img, $viewport, $canvas, $x, $y) = splice @_, 0, 5;
    my $vplabel = "photo_$viewport";

    $img->{$vplabel} = $img->prepare($viewport, $canvas)
        unless exists $img->{$vplabel};

    $canvas->createImage
    ( $x, $y
    , -image => $img->{$vplabel}
    , @_
    );

    $img;
}

sub getDimensions($)
{   my ($img, $viewport) = @_;
    my $photo = $img->{"photo_$viewport"};
    ($photo->width, $photo->height);
}

1;
