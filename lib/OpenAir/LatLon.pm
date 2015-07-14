package OpenAir::LatLon;

use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

subtype 'Latitude',
    as 'OpenAir::Degree',
    where { $_->totalSecs <= 90 * 60 * 60 },
    message { "Latitude can't be more than 90 degrees" };

subtype 'Longitude',
    as 'OpenAir::Degree',
    where { $_->totalSecs <= 180 * 60 * 60 },
    message { "Longitude can't be more than 180 degrees" };

has 'lat' => (
    is => 'rw',
    isa => 'Latitude',
    default => 0
    );

has 'lon' => (
    is => 'rw',
    isa => 'Longitude',
    default => 0
    );

sub eq {
    my $self = shift;
    my $other = shift;

    if (defined $other &&
	$self->lat->eq ($other->lat) &&
	$self->lon->eq ($other->lon)) {
	return 1;
    }
    return 0;
}

__PACKAGE__->meta->make_immutable;
