package Slim::Formats::APE;

# $Id: APE.pm 5405 2005-12-14 22:02:37Z dean $

# Logitech Media Server Copyright 2001-2011 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

=head1 NAME

Slim::Formats::APE

=head1 SYNOPSIS

my $tags = Slim::Formats::APE->getTag( $filename );

=head1 DESCRIPTION

Read tags embedded in Monkey's Audio (APE) files.

=head1 METHODS

=head2 getTag( $filename )

Extract and return audio information & any embedded metadata found.

=head1 SEE ALSO

L<Slim::Formats>

=cut

use strict;
use base qw(Slim::Formats);

use Audio::Scan;

my %tagMapping = (
	'TRACK'	       => 'TRACKNUM',
	'DATE'         => 'YEAR',
	'DISCNUMBER'   => 'DISC',
	'ALBUM ARTIST' => 'ALBUMARTIST', # bug 10724 - support APEv2 Album Artist
);

# Given a file, return a hash of name value pairs,
# where each name is a tag name.
sub getTag {
	my $class = shift;
	my $file  = shift || return {};
	
	my $s = Audio::Scan->scan($file);

	my $info = $s->{info};
	my $tags = $s->{tags};

	# Check for the presence of the info block here
	return unless $info->{song_length_ms};
	
	# Add info
	$tags->{SIZE}     = $info->{file_size};
	$tags->{BITRATE}  = $info->{bitrate};
	$tags->{SECS}     = $info->{song_length_ms} / 1000;
	$tags->{RATE}     = $info->{samplerate};
	$tags->{CHANNELS} = $info->{channels};
	
	$class->doTagMapping($tags);

	return $tags;
}

sub doTagMapping {
	my ( $class, $tags ) = @_;
	
	while ( my ($old, $new) = each %tagMapping ) {
		if ( exists $tags->{$old} ) {
			$tags->{$new} = delete $tags->{$old};
		}
	}
	
	# Flag if we have embedded cover art
	if ( exists $tags->{'COVER ART (FRONT)'} ) {
		if ( $ENV{AUDIO_SCAN_NO_ARTWORK} ) {
			$tags->{COVER_LENGTH} = $tags->{'COVER ART (FRONT)'};
		}
		else {
			$tags->{ARTWORK} = delete $tags->{'COVER ART (FRONT)'};
			$tags->{COVER_LENGTH} = length( $tags->{ARTWORK} );
		}
	}
}

=head2 getCoverArt( $filename )

Extract and return cover image from the file.

=cut

sub getCoverArt {
	my $class = shift;
	my $file  = shift || return undef;
	
	# Enable artwork in Audio::Scan
	local $ENV{AUDIO_SCAN_NO_ARTWORK} = 0;
	
	my $s = Audio::Scan->scan_tags($file);
	
	return $s->{tags}->{'COVER ART (FRONT)'};
}

1;
