# Copyright (C) 1999, Free Software Foundation Inc.

package PPresenter::Formatter::Markup;

# The markup formatter looks a bit like HTML, but certainly is
# not fully compliant.

use strict;
use PPresenter::Formatter;
use base 'PPresenter::Formatter';

use Tk;
use PPresenter::Formatter::Markup_parser;
use PPresenter::Formatter::Markup_placer;
#use PPresenter::Formatter::Markup_html;


use constant defaults =>
{ -name             => 'markup'
, -aliases          => [ 'Markup', 'hypertext', 'html', 'default' ]

, logicals          =>
  { BLOCKQUOTE => 'BQ'
  , CITE       => 'I'
  , CODE       => 'TT'
  , EM         => 'I'
  , FONT       => 'TEXT'
  , LARGE      => 'TEXT SIZE=+1'
  , BIG        => 'TEXT SIZE=+2'
  , HUGE       => 'TEXT SIZE=+3'
  , SMALL      => 'TEXT SIZE=-1'
  , STRONG     => 'TEXT SIZE=+1 B'
  , TITLE      => 'CENTER SIZE=+1'
  }
, specials          =>
  { amp        => '&'
  , lt         => '<'
  , gt         => '>'
  , quot       => '"'
  , quote      => '"'
  , nbsp       => ' '
  , dash       => '-'
  }
};

sub strip($$$)
{   my ($former, $show, $slide, $string) = @_;
    $string =~ s/<[^>]*>//g;
    $string;
}

sub addLogicals($@)
{   my $former  = shift;

    # The hash is replaced by a copy, and previous slides (if any)
    # will refer to the unchanged definition.
    $former->{logicals} = { %{$former->{logicals}}, @_ };
    $former;
}
sub addLogical($@) {shift->addLogicals(@_)}

sub addSpecialCharacters($@)
{   my $former  = shift;

    # The hash is replaced by a copy, and previous slides (if any)
    # will refer to the unchanged definition.
    $former->{specials} = { %{$former->{specials}}, @_ };
    $former;
}
sub addSpecialCharacter($@) {shift->addSpecialCharacters(@_)}

#
# Format
#

sub format($$)
{   my ($former, $args, $contents) = @_;

    my $parsed = $former->parse($contents);
#print $former->parseTree($parsed), "\n" if defined $parsed;

    $former->place($args, $parsed);
    # returns a program.
}

sub titleFormat($$)
{   my ($former, $view, $contents) = @_;
    return "<TITLE>$contents"
}

#
# Export
#

sub toHTML($$)
{   my ($former, $args, $contents) = @_;
    my $parsed = $former->parse($contents);
    $former->html($args, $parsed);
}

1;
