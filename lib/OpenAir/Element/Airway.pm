package OpenAir::Element::Airway;

use namespace::autoclean;
use Moose;

use OpenAir::Element::Point;

extends 'OpenAir::Element';

has 'point' => (
    is => 'rw',
    isa => 'OpenAir::Element::Point',
    required => 1
    );

__PACKAGE__->meta->make_immutable;
