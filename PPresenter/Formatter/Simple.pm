# Copyright (C) 1999, Free Software Foundation Inc.

# Simple formatter is a simplification of the markup formatter: you
# specify nesting with dashes, that's all.

package PPresenter::Formatter::Simple;

use strict;
use PPresenter::Formatter::Markup;
use base 'PPresenter::Formatter::Markup';

use Tk;

use constant defaults =>
{ -name    => 'simple'
, -aliases => undef
};

sub strip($$$;)
{   my ($self, $show, $slide, $string) = @_;
    $string =~ s/<[^>]*>//g;
    return $string;
}

#
# Format
#

sub format($$)
{   my ($self, $args, $contents) = @_;

    my @indents    = (0);
    my $indent     = 0;
    my $markup;

    foreach my $line (split /\n/, $contents)
    {
        my ($prefix, $dash, $text) = $line =~ /^(\s*(-)?\s*)(.*)\s*$/;
        my $prefix_length = length($prefix);

        # Detect indentation changes.

        if($prefix_length > $indents[-1])
        {   # Increase nesting.
            push @indents, $prefix_length;
            $markup .= "<UL>\n";
        }
        elsif($prefix_length==$indents[-1])
        { } # Keep indentation.
        else
        {   # Back from nestings.
            while($#indents)
            {   if($indents[-1] < $prefix_length)
                {   warn
  "Do not understand indentation on slide $args->{slide}, line\n  $line";
                    last;
                }
                last if $prefix_length == $indents[-1];
                $markup .= "</UL>\n";
                pop @indents;
            }
        }

        $markup .= (defined $dash ? '<LI>' : '') . $text . "<BR>\n";
    }

    $self->SUPER::format($args, $markup);
}

sub titleFormat($$)
{   my ($self, $slide, $title) = @_;
    "<TITLE>$title";
}

1;
