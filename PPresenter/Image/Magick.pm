# Copyright (C) 2000, Free Software Foundation FSF.

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

        print PPresenter::TRACE "Added Image::Magick image $img.\n";
    }

    @images;
}

sub prepare($$)
{   my ($img, $viewport, $canvas) = @_;

    #
    # Check if the preparation has been done before.
    #

    my $bgcolor = $canvas->cget(-background);
    my $vplabel = "photo_${viewport}_$bgcolor";
    return $vplabel if exists $img->{$vplabel};

    #
    # Read the raw image from file.
    #

    my ($orig, $copy);
    if(ref $img->{source})
    {   # Image already read from file.
        $orig = $img->{source};
    }
    else
    {   $orig = Image::Magick->new;
        if(my $err = $orig->Read($img->{source}))
        {   print "$err\n";
            return undef;
        }
    }

    if($orig->Get('matte'))
    {   # Scaling of transparent images and exporting Blobs to tkPhoto
        # for transparent images are both not perfectly implemented:
        # some dirty hacks required.
        $copy = $orig->Clone;

        # Fill-up transparent pixels with background color before
        # scaling or exporting.  Solution taken here is not perfect:
        # transparent pixel at least at (0,0) and all must be neighbours.
        # Looking for a better solution.
        $copy->Draw( primitive => 'Color', method => 'Replace'
                   , points    => '0,0',   pen    => $bgcolor);
#$copy->Opaque(color => $copy->Get('mattecolor'), pen => $bgcolor);
    }
    else
    {   # No transparency makes life much easier.
        $vplabel = "photo_$viewport";
        return $vplabel if exists $img->{$vplabel};
        $copy = $orig->Clone;
    }

    my $scaling = $img->scaling($viewport);

    warn "Poor image quality because $img is enlarged by factor $scaling.\n"
        if $^W && $scaling > 1.1;

    if($scaling<0.9 || $scaling>1.1)
    {   my ($width, $height) = $copy->Get('width', 'height');

        print PPresenter::TRACE
            "Scale image $img with $scaling for $viewport.\n";

        if(my $err = $copy->Zoom( width  => $width*$scaling
                                , height => $height*$scaling))
        {   print "$err\n";
        }
    }

    $img->{$vplabel} = $img->make_photo($copy, $canvas);
    $vplabel;
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

    my $label = $img->prepare($viewport, $canvas);

    $canvas->createImage($x, $y, -image => $img->{$label}, @_);

    $img;
}

sub dimensions($)
{   my ($img, $viewport) = @_;
    my $label = "photo_$viewport";
    my $photo = $img->{$label}
             || $img->{$label . '_' . $viewport->canvas->cget('-background')}
             || die "Cannot find prepared label for image $img on viewport $viewport.\n";

    ($photo->width, $photo->height);
}

1;
