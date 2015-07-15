package OpenAir::Element::Circle;

use namespace::autoclean;
use Moose;

extends 'OpenAir::Element';

has 'radius' => (
    is => 'rw',
    isa => 'OpenAir::PositiveNum',
    required => 1
    );

__PACKAGE__->meta->make_immutable;
