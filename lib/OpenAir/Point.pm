package OpenAir::Point;

use namespace::autoclean;
use Moose;

use OpenAir::Types;

extends 'OpenAir::Element';

has 'lat' => (
    is => 'rw',
    isa => 'OpenAir::Latitude',
    required => 1
    );

has 'lon' => (
    is => 'rw',
    isa => 'OpenAir::Longitude',
    required => 1
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
